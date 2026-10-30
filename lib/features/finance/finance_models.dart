import 'dart:math';

import '../../core/dates.dart';

/// A unified fee row for the resident (merged from receipts + fees).
class FeeItem {
  FeeItem({
    required this.id,
    required this.originalId,
    required this.type,
    required this.residentId,
    required this.month,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.concept,
  });

  /// Composite id: `receipt-<id>` or `fee-<id>` (drives `updateFeeStatus`).
  final String id;
  final String originalId;
  final String type; // 'receipt' | 'fee'
  final String residentId;
  final String month;
  final double amount;
  final String dueDate;
  final String status;
  final String concept;

  bool get isPaid => status == 'Pagado';

  /// True when the fee is unpaid and its due date has passed. The backend keeps
  /// an overdue receipt's status as `Pending` (the mora lives in `lateFee` and
  /// the checkout only accepts `Pending`), so "vencido" is derived from the
  /// date here — mirroring the admin's `ResidentFinancialStatusCalculator`.
  bool get isOverdue => !isPaid && Dates.isPastDue(dueDate);
}

class FinanceSettings {
  const FinanceSettings({this.baseMonthlyExpense = 150.0, this.lateFeeRate = 0.05});

  final double baseMonthlyExpense;
  final double lateFeeRate;
}

/// Receipt status values (ubiquitous language, shared with the web app).
class ReceiptStatus {
  static const String pending = 'Pending';
  static const String paid = 'Paid';
  static const String overdue = 'Overdue';
}

/// Tag appended to a receipt's `concept` when an admin waives the mora. It is
/// persisted server-side so automatic late fees never re-charge a forgiven
/// receipt (data value: never translated).
const String kMoraWaivedMarker = 'mora perdonada';

/// Raw receipt row used by the automatic late-fee (mora) pass.
class ReceiptRaw {
  ReceiptRaw({
    this.id,
    this.dueDate = '',
    this.amount = 0,
    this.status = ReceiptStatus.pending,
    this.lateFee = 0,
    this.concept = '',
  });

  final String? id;
  final String dueDate;
  final double amount;
  final String status;
  final double lateFee;
  final String concept;

  bool get isPaid => status == ReceiptStatus.paid;

  bool get isWaived => concept.contains(kMoraWaivedMarker);

  factory ReceiptRaw.fromJson(Map<String, dynamic> json) => ReceiptRaw(
        id: json['id']?.toString(),
        dueDate: json['dueDate']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status']?.toString() ?? ReceiptStatus.pending,
        lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0,
        concept: json['concept']?.toString() ?? '',
      );
}

class Payment {
  Payment({
    this.id,
    required this.residentId,
    this.feeId,
    this.feeMonth,
    this.concept,
    this.amount = 0,
    this.paidAt = '',
    this.method = 'Mercado Pago',
    this.reference,
  });

  final String? id;
  final String residentId;
  final String? feeId;
  final String? feeMonth;
  final String? concept;
  final double amount;
  final String paidAt;
  final String method;
  final String? reference;
}

/// Everything the resident finance screen renders.
class ResidentAccount {
  ResidentAccount({required this.fees, required this.payments, required this.settings});

  final List<FeeItem> fees;
  final List<Payment> payments;
  final FinanceSettings settings;

  double get pendingAmount =>
      fees.where((f) => !f.isPaid).fold(0.0, (sum, f) => sum + f.amount);

  double get paidTotal => payments.fold(0.0, (sum, p) => sum + p.amount);

  bool get hasPending => fees.any((f) => !f.isPaid);
}

// ------------------------------------------------------------------- DTOs

class ReceiptDto {
  ReceiptDto({this.id, this.residentId, this.dueDate, this.amount, this.status, this.lateFee, this.concept});

  final String? id;
  final String? residentId;
  final String? dueDate;
  final double? amount;
  final String? status;
  final double? lateFee;
  final String? concept;

  factory ReceiptDto.fromJson(Map<String, dynamic> json) => ReceiptDto(
        id: json['id']?.toString(),
        residentId: json['residentId']?.toString(),
        dueDate: json['dueDate']?.toString(),
        amount: _toDouble(json['amount']),
        status: json['status']?.toString(),
        lateFee: _toDouble(json['lateFee']),
        concept: json['concept']?.toString(),
      );
}

class FeeDto {
  FeeDto({this.id, this.residentId, this.month, this.amount, this.dueDate, this.status, this.concept});

  final String? id;
  final String? residentId;
  final String? month;
  final double? amount;
  final String? dueDate;
  final String? status;
  final String? concept;

  factory FeeDto.fromJson(Map<String, dynamic> json) => FeeDto(
        id: json['id']?.toString(),
        residentId: json['residentId']?.toString(),
        month: json['month']?.toString(),
        amount: _toDouble(json['amount']),
        dueDate: json['dueDate']?.toString(),
        status: json['status']?.toString(),
        concept: json['concept']?.toString(),
      );
}

class PaymentDto {
  PaymentDto({
    this.id,
    this.residentId,
    this.feeId,
    this.feeMonth,
    this.concept,
    this.amount,
    this.paidAt,
    this.method,
    this.reference,
  });

  final String? id;
  final String? residentId;
  final String? feeId;
  final String? feeMonth;
  final String? concept;
  final double? amount;
  final String? paidAt;
  final String? method;
  final String? reference;

  factory PaymentDto.fromJson(Map<String, dynamic> json) => PaymentDto(
        id: json['id']?.toString(),
        residentId: json['residentId']?.toString(),
        feeId: json['feeId']?.toString(),
        feeMonth: json['feeMonth']?.toString(),
        concept: json['concept']?.toString(),
        amount: _toDouble(json['amount']),
        paidAt: json['paidAt']?.toString(),
        method: json['method']?.toString(),
        reference: json['reference']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'residentId': residentId,
        'feeId': feeId,
        'feeMonth': feeMonth,
        'concept': concept,
        'amount': amount,
        'paidAt': paidAt,
        'method': method,
        'reference': reference,
      };
}

/// Maps combined receipts + fees rows into the unified resident fee view.
///
/// Residents are only charged the base quota + late fee (shared-service extras
/// never count here), and a fee row duplicating a receipt's due date is skipped
/// so the same period is never billed twice.
List<FeeItem> mapFees(List<ReceiptDto> receipts, List<FeeDto> fees, String residentId) {
  String first10(String? value) {
    final v = value ?? '';
    return v.substring(0, min(10, v.length));
  }

  String conceptOr(String? concept, String fallback) {
    final c = concept ?? '';
    return c.trim().isEmpty ? fallback : c;
  }

  final mappedReceipts = receipts.map((dto) {
    return FeeItem(
      id: 'receipt-${dto.id ?? ''}',
      originalId: dto.id ?? '',
      type: 'receipt',
      residentId: dto.residentId ?? '',
      month: Dates.monthYearLabel(dto.dueDate),
      amount: (dto.amount ?? 0) + (dto.lateFee ?? 0),
      dueDate: dto.dueDate ?? '',
      status: dto.status == 'Paid' ? 'Pagado' : 'Pendiente',
      concept: conceptOr(dto.concept, 'Mantenimiento'),
    );
  }).toList();

  final receiptDueDates = receipts
      .map((dto) => (dto.dueDate == null || dto.dueDate!.trim().isEmpty)
          ? null
          : first10(dto.dueDate))
      .whereType<String>()
      .toSet();

  final mappedFees = fees.where((dto) {
    return !receiptDueDates.contains(first10(dto.dueDate));
  }).map((dto) {
    return FeeItem(
      id: 'fee-${dto.id ?? ''}',
      originalId: dto.id ?? '',
      type: 'fee',
      residentId: dto.residentId ?? '',
      month: dto.month ?? 'Mes actual',
      amount: dto.amount ?? 0,
      dueDate: dto.dueDate ?? '',
      status: dto.status ?? 'Pendiente',
      concept: conceptOr(dto.concept, 'Cuota mantenimiento'),
    );
  }).toList();

  final combined = [...mappedReceipts, ...mappedFees];
  combined.sort((a, b) => b.dueDate.compareTo(a.dueDate));
  return combined;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
