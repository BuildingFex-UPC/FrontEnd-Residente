import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/dates.dart';
import '../../core/repositories.dart';
import '../../core/session_repository.dart';
import '../finance/finance_controller.dart';
import '../finance/finance_models.dart';
import '../incidents/incidents_repository.dart';
import '../spaces/socialspaces_models.dart';
import '../dashboard/dashboard_repository.dart';

class FinanceSummary {
  const FinanceSummary({this.paid = 0, this.pending = 0, this.overdue = 0});

  final double paid;
  final double pending;
  final double overdue;

  double get total => paid + pending;
}

class DashboardState {
  DashboardState({
    this.loading = true,
    this.error,
    this.fees = const [],
    this.payments = const [],
    this.announcements = const [],
    this.incidents = const [],
    this.reservations = const [],
    this.spacesById = const {},
  });

  final bool loading;
  final String? error;
  final List<FeeItem> fees;
  final List<Payment> payments;
  final List<Announcement> announcements;
  final List<Incident> incidents;
  final List<Reservation> reservations;
  final Map<String, Space> spacesById;

  FinanceSummary get financeSummary {
    final paid = fees.where((f) => f.isPaid).fold<double>(0, (s, f) => s + f.amount);
    final pendingFees = fees.where((f) => !f.isPaid).toList();
    final pending = pendingFees.fold<double>(0, (s, f) => s + f.amount);
    final today = DateTime.now();
    final overdue = pendingFees
        .where((f) {
          final due = Dates.ymdOrNull(f.dueDate);
          return due != null && due.isBefore(DateTime(today.year, today.month, today.day));
        })
        .fold<double>(0, (s, f) => s + f.amount);
    return FinanceSummary(paid: paid, pending: pending, overdue: overdue);
  }

  List<Announcement> get activeAnnouncements =>
      announcements.where((a) => a.isActive).toList();

  List<Reservation> get todayReservations =>
      reservations.where((r) => r.date == Dates.todayYmd()).toList();

  List<Reservation> get upcomingReservations {
    final today = Dates.todayYmd();
    final list = reservations.where((r) => r.date.compareTo(today) > 0).toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
      });
    return list;
  }

  int get openIncidents => incidents.where((i) => i.status == IncidentStatus.open).length;
  int get inProgressIncidents =>
      incidents.where((i) => i.status == IncidentStatus.inProgress).length;
  int get resolvedIncidents =>
      incidents.where((i) => i.status == IncidentStatus.resolved).length;

  DashboardState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<FeeItem>? fees,
    List<Payment>? payments,
    List<Announcement>? announcements,
    List<Incident>? incidents,
    List<Reservation>? reservations,
    Map<String, Space>? spacesById,
  }) =>
      DashboardState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        fees: fees ?? this.fees,
        payments: payments ?? this.payments,
        announcements: announcements ?? this.announcements,
        incidents: incidents ?? this.incidents,
        reservations: reservations ?? this.reservations,
        spacesById: spacesById ?? this.spacesById,
      );
}

/// Resident dashboard: finance KPIs, announcements, incidents and reservations.
class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(load);
    return DashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final financeRepo = ref.read(financeRepositoryProvider);
      final spacesRepo = ref.read(socialspacesRepositoryProvider);
      final incidentsRepo = ref.read(incidentsRepositoryProvider);
      final announcementsRepo = ref.read(announcementsRepositoryProvider);
      final residentId = ref.read(sessionRepositoryProvider).current?.profile.id ?? '';

      // Apply the automatic late-fee (mora) pass first, exactly like the
      // finance screen does. Without this the dashboard read stale amounts
      // (e.g. 150.0 while Finanzas showed the 157.5 with mora already applied).
      // Best-effort: never let that side effect blank the dashboard.
      try {
        await financeRepo.autoApplyLateFees();
      } catch (_) {
        // Ignore and still show the current (pre-mora) amounts.
      }

      final results = await Future.wait<dynamic>([
        financeRepo.listFees(),
        financeRepo.listPayments(),
        _guard(announcementsRepo.list()),
        _guard(incidentsRepo.listMine()),
        _guard(spacesRepo.listByResident(residentId)),
        _guard(spacesRepo.listSpaces()),
      ]);

      final fees = results[0] as List<FeeItem>;
      final payments = results[1] as List<Payment>;
      final announcements = results[2] as List<Announcement>;
      final incidents = results[3] as List<Incident>;
      final reservations = results[4] as List<Reservation>;
      final spaces = results[5] as List<Space>;

      reservations.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
      });

      state = state.copyWith(
        loading: false,
        fees: fees,
        payments: payments,
        announcements: announcements,
        incidents: incidents,
        reservations: reservations,
        spacesById: {for (final s in spaces) if (s.id != null) s.id!: s},
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e is AppException ? e.userMessage() : AppException.unexpected(e).userMessage(),
      );
    }
  }

  /// Best-effort side loads: an empty list on failure so one bad endpoint
  /// doesn't blank the whole dashboard.
  static Future<List<T>> _guard<T>(Future<List<T>> future) async {
    try {
      return await future;
    } catch (_) {
      return <T>[];
    }
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(DashboardController.new);
