import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/i18n.dart';
import '../../core/repositories.dart';
import '../../core/session_repository.dart';
import '../spaces/socialspaces_models.dart';

final myReservationsControllerProvider =
    StateNotifierProvider<MyReservationsController, MyReservationsState>(
  (ref) => MyReservationsController(ref),
);

class MyReservationsState {
  const MyReservationsState({
    this.loading = true,
    this.error,
    this.reservations = const [],
    this.spacesById = const {},
    this.editing,
    this.guestInputs = const [],
    this.saving = false,
    this.formError,
    this.message,
  });

  final bool loading;
  final String? error;
  final List<Reservation> reservations;
  final Map<String, Space> spacesById;

  /// Reservation whose guest list is being edited (null = no dialog open).
  final Reservation? editing;
  final List<GuestInput> guestInputs;
  final bool saving;
  final String? formError;
  final String? message;

  MyReservationsState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<Reservation>? reservations,
    Map<String, Space>? spacesById,
    Reservation? editing,
    bool clearEditing = false,
    List<GuestInput>? guestInputs,
    bool? saving,
    String? formError,
    bool clearFormError = false,
    String? message,
    bool clearMessage = false,
  }) =>
      MyReservationsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        reservations: reservations ?? this.reservations,
        spacesById: spacesById ?? this.spacesById,
        editing: clearEditing ? null : (editing ?? this.editing),
        guestInputs: guestInputs ?? this.guestInputs,
        saving: saving ?? this.saving,
        formError: clearFormError ? null : (formError ?? this.formError),
        message: clearMessage ? null : (message ?? this.message),
      );
}

/// "Mis reservas": guest-list editing, invite QR and share link.
class MyReservationsController extends StateNotifier<MyReservationsState> {
  MyReservationsController(this._ref) : super(const MyReservationsState());

  final Ref _ref;

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = _ref.read(socialspacesRepositoryProvider);
      final residentId = _ref.read(sessionRepositoryProvider).current?.profile.id ?? '';
      final reservations = await repo.listByResident(residentId);
      final spaces = await repo.listSpaces();
      reservations.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.startTime.compareTo(a.startTime);
      });
      state = state.copyWith(
        loading: false,
        reservations: reservations,
        spacesById: {for (final s in spaces) if (s.id != null) s.id!: s},
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageOf(e));
    }
  }

  /// Opens the guest editor for [reservation], prefilled with its guests.
  void openEditor(Reservation reservation) {
    state = state.copyWith(
      editing: reservation,
      guestInputs: [
        for (final g in reservation.guests) GuestInput(id: g.id, name: g.name),
        // Always show at least one blank row so the resident can add guests.
        if (reservation.guests.isEmpty) GuestInput(),
      ],
      clearFormError: true,
    );
  }

  void closeEditor() => state = state.copyWith(clearEditing: true);

  void setGuestName(int index, String name) {
    final inputs = [...state.guestInputs];
    if (index < 0 || index >= inputs.length) return;
    final previous = inputs[index];
    inputs[index] = GuestInput(id: previous.id, name: name);
    state = state.copyWith(guestInputs: inputs, clearFormError: true);
  }

  /// Appends a blank row while below the guest cap.
  void addGuestRow() {
    if (state.guestInputs.length >= ReservationRules.maxGuests) return;
    state = state.copyWith(guestInputs: [...state.guestInputs, GuestInput()]);
  }

  Future<void> saveGuests() async {
    final reservation = state.editing;
    if (reservation?.id == null) return;
    state = state.copyWith(saving: true, clearFormError: true);
    try {
      final updated = await _ref
          .read(socialspacesRepositoryProvider)
          .updateGuests(reservation!.id!, state.guestInputs);
      // Merge the fresh row into the list without a full reload.
      final reservations = [
        for (final r in state.reservations)
          if (r.id == updated.id) updated else r,
      ];
      state = state.copyWith(
        saving: false,
        clearEditing: true,
        reservations: reservations,
        message: AppTexts.translate('resv.guestsUpdated'),
      );
    } catch (e) {
      state = state.copyWith(saving: false, formError: _messageOf(e));
    }
  }

  void dismissMessage() => state = state.copyWith(clearMessage: true);
}

String _messageOf(Object e) =>
    e is AppException ? e.userMessage() : AppException.unexpected(e).userMessage();
