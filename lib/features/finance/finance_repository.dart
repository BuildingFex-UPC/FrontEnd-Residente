import '../../core/api_client.dart';
import '../../core/dates.dart';
import '../../core/session_repository.dart';
import 'finance_models.dart';

/// Result of starting a Mercado Pago Checkout Pro session.
class PaymentCheckout {
  PaymentCheckout({this.preferenceId, this.initPoint, this.demo = false});

  final String? preferenceId;
  final String? initPoint;
  final bool demo;
}

class PaymentConfirmation {
  PaymentConfirmation({this.reconciled = false, this.itemsPaid = 0, this.paidAt});

  final bool reconciled;
  final int itemsPaid;
  final String? paidAt;
}

/// Resident-side finance data access (fees, history and Mercado Pago).
///
/// Every query is multi-tenant scoped by `ownerAdminId` and filtered to this
/// resident via `residentId`.
class FinanceRepository {
  FinanceRepository(this._api, this._session);

  final ApiClient _api;
  final SessionRepository _session;

  String get _residentId =>
      _session.current?.profile.id ?? '';

  Map<String, String> _scopedResident([Map<String, String> extra = const {}]) =>
      _api.ownerParams({...extra, 'residentId': _residentId});

  /// `GET financeSettings` (falls back to defaults when absent).
  Future<FinanceSettings> getSettings() => apiCall(() async {
        try {
          final response = await _api.dio.get<List<dynamic>>(
            'financeSettings',
            queryParameters: _api.ownerParams(),
          );
          final rows = response.data ?? const [];
          if (rows.isEmpty) return const FinanceSettings();
          final first = (rows.first as Map?)?.cast<String, dynamic>() ?? const {};
          return FinanceSettings(
            baseMonthlyExpense: (first['baseMonthlyExpense'] as num?)?.toDouble() ?? 150.0,
            lateFeeRate: (first['lateFeeRate'] as num?)?.toDouble() ?? 0.05,
          );
        } catch (e) {
          if (_isNotFound(e)) return const FinanceSettings();
          rethrow;
        }
      });

  /// Merged receipts + fees for this resident (see [mapFees]).
  Future<List<FeeItem>> listFees() => apiCall(() async {
        final receiptsResponse = await _api.dio.get<List<dynamic>>(
          'receipts',
          queryParameters: _scopedResident(),
        );
        final feesResponse = await _api.dio.get<List<dynamic>>(
          'fees',
          queryParameters: _scopedResident(),
        );
        final receipts = (receiptsResponse.data ?? const [])
            .map((e) => ReceiptDto.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        final fees = (feesResponse.data ?? const [])
            .map((e) => FeeDto.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        return mapFees(receipts, fees, _residentId);
      });

  Future<List<Payment>> listPayments() => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'payments',
          queryParameters: _scopedResident(),
        );
        return (response.data ?? const []).map((e) {
          final dto = PaymentDto.fromJson((e as Map).cast<String, dynamic>());
          return Payment(
            id: dto.id,
            residentId: dto.residentId ?? '',
            feeId: dto.feeId,
            feeMonth: dto.feeMonth,
            concept: dto.concept,
            amount: dto.amount ?? 0,
            paidAt: dto.paidAt ?? '',
            method: dto.method ?? 'Mercado Pago',
            reference: dto.reference,
          );
        }).toList();
      });

  /// Marks a composite fee id as paid (`receipt-`/`fee-` prefixed).
  Future<void> updateFeeStatus(String feeId, String status) => apiCall(() async {
        if (feeId.startsWith('receipt-')) {
          final realId = feeId.substring('receipt-'.length);
          final statusEn = status == 'Pagado' ? ReceiptStatus.paid : ReceiptStatus.pending;
          await _api.dio.patch<dynamic>('receipts/$realId', data: {'status': statusEn});
        } else if (feeId.startsWith('fee-')) {
          final realId = feeId.substring('fee-'.length);
          await _api.dio.patch<dynamic>('fees/$realId', data: {'status': status});
        }
      });

  /// Raw receipts for this resident (used by the automatic late-fee pass).
  Future<List<ReceiptRaw>> listReceiptsRaw() => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'receipts',
          queryParameters: _scopedResident(),
        );
        return (response.data ?? const [])
            .map((e) => ReceiptRaw.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });

  /// Partially patches a receipt (`status`, `lateFee` or `concept`).
  Future<void> updateReceipt(
    String id, {
    String? status,
    double? lateFee,
    String? concept,
  }) =>
      apiCall(() async {
        final data = <String, dynamic>{};
        if (status != null) data['status'] = status;
        if (lateFee != null) data['lateFee'] = lateFee;
        if (concept != null) data['concept'] = concept;
        if (data.isEmpty) return;
        await _api.dio.patch<dynamic>('receipts/$id', data: data);
      });

  /// Applies the configured late fee automatically whenever a receipt is past
  /// due (the web nightly cron, now run on every finance load). It also heals
  /// legacy `Overdue` rows back to `Pending`: the backend checkout and
  /// reconcile only accept `Pending` receipts, so overdue ones must stay
  /// payable with the mora carried in `lateFee`. Receipts tagged as waived are
  /// skipped so a forgiven mora is never re-charged.
  Future<int> autoApplyLateFees() async {
    final settings = await getSettings();
    final receipts = await listReceiptsRaw();
    var updated = 0;
    for (final receipt in receipts) {
      if (receipt.isPaid) continue;
      final needsHeal = receipt.status == ReceiptStatus.overdue;
      final needsFee =
          Dates.isPastDue(receipt.dueDate) && !receipt.isWaived && receipt.lateFee == 0;
      if (!needsHeal && !needsFee) continue;
      final id = receipt.id;
      if (id == null || id.isEmpty) continue;
      await updateReceipt(
        id,
        status: needsHeal ? ReceiptStatus.pending : null,
        lateFee: needsFee ? receipt.amount * settings.lateFeeRate : null,
      );
      updated++;
    }
    return updated;
  }

  Future<Payment> addPayment(Payment payment) => apiCall(() async {
        final body = <String, dynamic>{
          'residentId': payment.residentId,
          'feeId': payment.feeId,
          'feeMonth': payment.feeMonth,
          'concept': payment.concept,
          'amount': payment.amount,
          'paidAt': payment.paidAt,
          'method': payment.method,
          'reference': payment.reference,
          'ownerAdminId': _session.activeDataOwnerId,
        };
        final response = await _api.dio.post<dynamic>('payments', data: body);
        final dto = PaymentDto.fromJson(
          (response.data as Map?)?.cast<String, dynamic>() ?? const {},
        );
        return Payment(
          id: dto.id,
          residentId: dto.residentId ?? payment.residentId,
          feeId: dto.feeId,
          feeMonth: dto.feeMonth,
          concept: dto.concept,
          amount: dto.amount ?? payment.amount,
          paidAt: dto.paidAt ?? payment.paidAt,
          method: dto.method ?? payment.method,
          reference: dto.reference,
        );
      });

  /// `POST api/v1/payments/checkout`
  Future<PaymentCheckout> checkout({String? payerEmail}) => apiCall(() async {
        final response = await _api.dio.post<dynamic>(
          'api/v1/payments/checkout',
          data: {
            'residentId': _residentId,
            'ownerAdminId': _session.activeDataOwnerId,
            'payerEmail': payerEmail,
          },
        );
        final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
        return PaymentCheckout(
          preferenceId: data['preferenceId']?.toString(),
          initPoint: data['initPoint']?.toString(),
          demo: data['demo'] as bool? ?? false,
        );
      });

  /// `POST api/v1/payments/confirm`
  Future<PaymentConfirmation> confirm({
    String? paymentId,
    bool demo = false,
  }) =>
      apiCall(() async {
        final response = await _api.dio.post<dynamic>(
          'api/v1/payments/confirm',
          data: {
            'residentId': _residentId,
            'ownerAdminId': _session.activeDataOwnerId,
            'paymentId': paymentId,
            'demo': demo,
          },
        );
        final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
        return PaymentConfirmation(
          reconciled: data['reconciled'] as bool? ?? false,
          itemsPaid: (data['itemsPaid'] as num?)?.toInt() ?? 0,
          paidAt: data['paidAt']?.toString(),
        );
      });

  /// Registers one payment row per pending fee after a successful checkout.
  Future<List<Payment>> recordPayment({String? reference, String? paidAt}) async {
    final fees = await listFees();
    final pending = fees.where((f) => !f.isPaid).toList();
    if (pending.isEmpty) return [];
    final timestamp = paidAt ?? Dates.nowIso();
    final recorded = <Payment>[];
    for (final fee in pending) {
      await updateFeeStatus(fee.id, 'Pagado');
      final payment = await addPayment(
        Payment(
          residentId: _residentId,
          feeId: fee.id,
          feeMonth: fee.month,
          concept: fee.concept,
          amount: fee.amount,
          paidAt: timestamp,
          method: 'Mercado Pago',
          reference: reference,
        ),
      );
      recorded.add(payment);
    }
    return recorded;
  }
}

bool _isNotFound(Object e) => e.toString().contains('404');
