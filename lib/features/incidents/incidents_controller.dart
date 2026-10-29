import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/i18n.dart';
import '../../core/repositories.dart';
import 'incidents_repository.dart';

final incidentsControllerProvider =
    StateNotifierProvider<IncidentsController, IncidentsState>(
  (ref) => IncidentsController(ref),
);

class IncidentsState {
  const IncidentsState({
    this.loading = true,
    this.error,
    this.incidents = const [],
    this.description = '',
    this.submitting = false,
    this.editing,
    this.editDescription = '',
    this.deletingId,
    this.message,
  });

  final bool loading;
  final String? error;
  final List<Incident> incidents;

  /// Report form.
  final String description;
  final bool submitting;

  /// Edit dialog (incident id being edited, null = closed).
  final String? editing;
  final String editDescription;

  /// Incident id being deleted (null = none).
  final String? deletingId;

  final String? message;

  IncidentsState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<Incident>? incidents,
    String? description,
    bool? submitting,
    String? editing,
    bool clearEditing = false,
    String? editDescription,
    String? deletingId,
    bool clearDeletingId = false,
    String? message,
    bool clearMessage = false,
  }) =>
      IncidentsState(
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        incidents: incidents ?? this.incidents,
        description: description ?? this.description,
        submitting: submitting ?? this.submitting,
        editing: clearEditing ? null : (editing ?? this.editing),
        editDescription: editDescription ?? this.editDescription,
        deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
        message: clearMessage ? null : (message ?? this.message),
      );
}

/// Resident incidents: report new ones and review their status.
///
/// The constructor does NOT load: the provider is cached (non-autoDispose)
/// and the shell reuses it, so the screen triggers [reload] each time the tab
/// is opened to pick up changes made by the admin in the meantime.
class IncidentsController extends StateNotifier<IncidentsState> {
  IncidentsController(this._ref) : super(const IncidentsState());

  final Ref _ref;

  Future<void> reload() => _load();

  Future<void> _load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final incidents = await _ref.read(incidentsRepositoryProvider).listMine();
      state = state.copyWith(loading: false, incidents: incidents);
    } catch (e) {
      state = state.copyWith(loading: false, error: _messageOf(e));
    }
  }

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  /// Reports a new incident for the signed-in resident.
  Future<void> report() async {
    final description = state.description.trim();
    if (description.isEmpty) {
      state = state.copyWith(
        message: AppTexts.translate('err.INCIDENT_DESCRIPTION_REQUIRED'),
      );
      return;
    }
    state = state.copyWith(submitting: true, clearMessage: true);
    try {
      final created = await _ref.read(incidentsRepositoryProvider).report(description);
      state = state.copyWith(
        submitting: false,
        description: '',
        incidents: [created, ...state.incidents],
        message: AppTexts.translate('inc.msg.sent'),
      );
    } catch (e) {
      state = state.copyWith(submitting: false, message: _messageOf(e));
    }
  }

  void openEditor(Incident incident) {
    state = state.copyWith(editing: incident.id, editDescription: incident.description);
  }

  void closeEditor() => state = state.copyWith(clearEditing: true);

  void setEditDescription(String value) =>
      state = state.copyWith(editDescription: value);

  /// Saves the edited description (status/provider are admin-owned).
  Future<void> saveEdit() async {
    final id = state.editing;
    if (id == null) return;
    final description = state.editDescription.trim();
    if (description.isEmpty) {
      state = state.copyWith(
        message: AppTexts.translate('err.INCIDENT_DESCRIPTION_REQUIRED'),
      );
      return;
    }
    state = state.copyWith(submitting: true, clearMessage: true);
    try {
      await _ref.read(incidentsRepositoryProvider).updateDescription(id, description);
      final incidents = [
        for (final i in state.incidents)
          if (i.id == id)
            Incident(
              id: i.id,
              residentId: i.residentId,
              residentName: i.residentName,
              description: description,
              status: i.status,
              createdAt: i.createdAt,
              provider: i.provider,
            )
          else
            i,
      ];
      state = state.copyWith(
        submitting: false,
        clearEditing: true,
        incidents: incidents,
        message: AppTexts.translate('inc.msg.updated'),
      );
    } catch (e) {
      state = state.copyWith(submitting: false, message: _messageOf(e));
    }
  }

  void requestDelete(String id) => state = state.copyWith(deletingId: id);

  void cancelDelete() => state = state.copyWith(clearDeletingId: true);

  Future<void> confirmDelete() async {
    final id = state.deletingId;
    if (id == null) return;
    state = state.copyWith(deletingId: null, submitting: true, clearMessage: true);
    try {
      await _ref.read(incidentsRepositoryProvider).remove(id);
      state = state.copyWith(
        submitting: false,
        incidents: [for (final i in state.incidents) if (i.id != id) i],
        message: AppTexts.translate('inc.msg.deleted'),
      );
    } catch (e) {
      state = state.copyWith(submitting: false, message: _messageOf(e));
    }
  }

  void dismissMessage() => state = state.copyWith(clearMessage: true);
}

String _messageOf(Object e) =>
    e is AppException ? e.userMessage() : AppException.unexpected(e).userMessage();
