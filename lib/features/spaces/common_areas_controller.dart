import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/dates.dart';
import '../../core/i18n.dart';
import '../../core/repositories.dart';
import '../../core/session_repository.dart';
import 'socialspaces_models.dart';

final socialspacesControllerProvider =
    StateNotifierProvider<SpacesController, SpacesState>((ref) => SpacesController(ref));

class SpacesState {
  const SpacesState({
    this.loading = true,
    this.error,
    this.spaces = const [],
    this.selectedSpace,
    this.spaceReservations = const [],
    this.loadingReservations = false,
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    this.formError,
    this.submitting = false,
    this.message,
  });

  final bool loading;
  final String? error;
  final List<Space> spaces;
  final Space? selectedSpace;
  final List<Reservation> spaceReservations;
  final bool loadingReservations;
  final String date;
  final String startTime;
  final String endTime;
  final String? formError;
  final bool submitting;
  final String? message;

  SpacesState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<Space>? spaces,
    Space? selectedSpace,
    bool clearSelectedSpace = false,
    List<Reservation>? spaceReservations,
    bool? loadingReservations,
    String? date,
    String? startTime,
    String? endTime,
    String? formError,
    bool clearFormError = false,
    bool? submitting,
    String? message,
    bool clearMessage = false,
  }) =>
      SpacesState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        spaces: spaces ?? this.spaces,
        selectedSpace: clearSelectedSpace ? null : (selectedSpace ?? this.selectedSpace),
        spaceReservations: spaceReservations ?? this.spaceReservations,
        loadingReservations: loadingReservations ?? this.loadingReservations,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        formError: clearFormError ? null : (formError ?? this.formError),
        submitting: submitting ?? this.submitting,
        message: clearMessage ? null : (message ?? this.message),
      );
}

/// Common-areas flow: browse spaces, pick a slot and reserve it.
class SpacesController extends StateNotifier<SpacesState> {
  SpacesController(this._ref) : super(const SpacesState()) {
    _load();
  }

  final Ref _ref;

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final spaces = await _ref.read(socialspacesRepositoryProvider).listSpaces();
      state = state.copyWith(loading: false, spaces: spaces);
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageOf(e));
    }
  }

  void selectSpace(Space space) {
    state = state.copyWith(
      selectedSpace: space,
      date: Dates.todayYmd(),
      startTime: '',
      endTime: '',
      clearFormError: true,
      spaceReservations: const [],
    );
    _loadReservations();
  }

  void clearSelection() =>
      state = state.copyWith(clearSelectedSpace: true, clearFormError: true);

  Future<void> _loadReservations() async {
    final space = state.selectedSpace;
    if (space?.id == null) return;
    state = state.copyWith(loadingReservations: true);
    try {
      final list =
          await _ref.read(socialspacesRepositoryProvider).listBySpace(space!.id!);
      state = state.copyWith(loadingReservations: false, spaceReservations: list);
    } catch (_) {
      state = state.copyWith(loadingReservations: false);
    }
  }

  void setDate(String value) =>
      state = state.copyWith(date: value, clearFormError: true);

  void setStartTime(String value) =>
      state = state.copyWith(startTime: value, clearFormError: true);

  void setEndTime(String value) =>
      state = state.copyWith(endTime: value, clearFormError: true);

  /// Reserves the selected space for the chosen slot.
  Future<void> reserve() async {
    final s = state;
    final space = s.selectedSpace;
    if (space == null) return;
    if (s.date.isEmpty || s.startTime.isEmpty || s.endTime.isEmpty) {
      state = state.copyWith(
        formError: AppTexts.translate('err.RESERVATION_FIELDS_REQUIRED'),
      );
      return;
    }
    if (!ReservationRules.timeRangeValid(s.startTime, s.endTime)) {
      state = state.copyWith(
        formError: AppTexts.translate('err.RESERVATION_TIME_INVALID'),
      );
      return;
    }
    state = state.copyWith(submitting: true, clearFormError: true, clearMessage: true);
    final profile = _ref.read(sessionRepositoryProvider).current?.profile;
    try {
      await _ref.read(socialspacesRepositoryProvider).add(
            spaceId: space.id!,
            residentName: profile?.name ?? '',
            residentCode: profile?.code ?? '',
            date: s.date,
            startTime: s.startTime,
            endTime: s.endTime,
          );
      state = state.copyWith(
        submitting: false,
        clearSelectedSpace: true,
        message: AppTexts.format('services.reservedMessage', {'name': space.name}),
      );
      await _loadReservations();
    } catch (e) {
      state = state.copyWith(submitting: false, formError: _messageOf(e));
    }
  }

  void dismissMessage() => state = state.copyWith(clearMessage: true);
}

String _messageOf(Object e) =>
    e is AppException ? e.userMessage() : AppException.unexpected(e).userMessage();
