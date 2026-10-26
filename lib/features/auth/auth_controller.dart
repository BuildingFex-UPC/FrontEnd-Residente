import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../core/i18n.dart';
import '../../core/invite_codes.dart';
import '../../core/session.dart';
import '../../core/session_repository.dart';
import 'auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

class AuthState {
  const AuthState({
    this.initialized = false,
    this.session,
    this.loading = false,
    this.error,
    this.inviteMode = false,
    this.inviteCode = '',
    this.inviteLoading = false,
    this.inviteError,
    this.inviteResident,
    this.inviteEmail = '',
    this.invitePassword = '',
  });

  final bool initialized;
  final Session? session;
  final bool loading;
  final String? error;
  final bool inviteMode;
  final String inviteCode;
  final bool inviteLoading;
  final String? inviteError;
  final ResidentInvite? inviteResident;
  final String inviteEmail;
  final String invitePassword;

  bool get hasSession => session != null;

  AuthState copyWith({
    bool? initialized,
    Session? session,
    bool clearSession = false,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? inviteMode,
    String? inviteCode,
    bool? inviteLoading,
    String? inviteError,
    bool clearInviteError = false,
    ResidentInvite? inviteResident,
    bool clearInviteResident = false,
    String? inviteEmail,
    String? invitePassword,
  }) =>
      AuthState(
        initialized: initialized ?? this.initialized,
        session: clearSession ? null : (session ?? this.session),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        inviteMode: inviteMode ?? this.inviteMode,
        inviteCode: inviteCode ?? this.inviteCode,
        inviteLoading: inviteLoading ?? this.inviteLoading,
        inviteError: clearInviteError ? null : (inviteError ?? this.inviteError),
        inviteResident:
            clearInviteResident ? null : (inviteResident ?? this.inviteResident),
        inviteEmail: inviteEmail ?? this.inviteEmail,
        invitePassword: invitePassword ?? this.invitePassword,
      );
}

class AuthController extends Notifier<AuthState> {
  Timer? _debounce;

  @override
  AuthState build() {
    final session = ref.read(sessionRepositoryProvider).current;
    return AuthState(initialized: true, session: session);
  }

  void _signIn(AuthResult result) {
    ensureResidentRole(result.profile);
    final session = Session(profile: result.profile, token: result.token);
    ref.read(sessionRepositoryProvider).signIn(session);
    state = state.copyWith(session: session, loading: false, clearError: true);
  }

  Future<void> login(String email, String password) async {
    if (state.loading) return;
    if (!AuthRepository.isValidEmail(email)) {
      state = state.copyWith(error: AppTexts.translate('auth.error.invalid_email'));
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(error: AppTexts.translate('auth.error.password_required'));
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email.trim().toLowerCase(), password);
      _signIn(result);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _messageOf(e),
      );
    }
  }

  void openInviteMode() => state = state.copyWith(
        inviteMode: true,
        clearInviteError: true,
        clearError: true,
        clearInviteResident: true,
      );

  void closeInviteMode() {
    _debounce?.cancel();
    state = state.copyWith(
      inviteMode: false,
      clearInviteError: true,
      clearInviteResident: true,
      inviteCode: '',
    );
  }

  /// Typing in the invite field: extract a code from a pasted message and
  /// auto-search when it looks complete; otherwise debounce the lookup.
  void onInviteCodeChange(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (InviteCodes.looksLikeMessage(trimmed)) {
      final code = InviteCodes.extract(trimmed);
      if (code == null || code.isEmpty) {
        state = state.copyWith(
          inviteCode: trimmed,
          inviteError: AppTexts.translate('auth.invite.no_code'),
        );
        return;
      }
      state = state.copyWith(inviteCode: code, clearInviteError: true);
      _lookup(code);
      return;
    }
    state = state.copyWith(inviteCode: trimmed, clearInviteError: true);
    if (InviteCodes.canAutoSearch(trimmed)) {
      _debounce = Timer(const Duration(milliseconds: 450), () => _lookup(trimmed));
    }
  }

  void lookupInvite() {
    final raw = state.inviteCode;
    final code = InviteCodes.extract(raw) ?? raw.trim();
    if (code.isEmpty) {
      state = state.copyWith(
        inviteError: AppTexts.translate('auth.error.invite_code_required'),
      );
      return;
    }
    state = state.copyWith(inviteCode: code);
    _debounce?.cancel();
    _lookup(code);
  }

  Future<void> _lookup(String code) async {
    state = state.copyWith(inviteLoading: true, clearInviteError: true);
    try {
      final resident = await ref.read(authRepositoryProvider).findResidentByInviteCode(code);
      state = state.copyWith(inviteLoading: false, inviteResident: resident);
    } catch (e) {
      final appError = _asAppException(e);
      final message = appError.code == 'RESIDENT_NOT_FOUND'
          ? AppTexts.format('auth.error.resident_not_found', {'code': code})
          : appError.userMessage();
      state = state.copyWith(inviteLoading: false, inviteError: message);
    }
  }

  void onInviteEmailChange(String value) =>
      state = state.copyWith(inviteEmail: value, clearInviteError: true);

  void onInvitePasswordChange(String value) =>
      state = state.copyWith(invitePassword: value, clearInviteError: true);

  Future<void> acceptInvite() async {
    final s = state;
    final resident = s.inviteResident;
    if (resident == null) return;
    final emailError = AuthRepository.isValidEmail(s.inviteEmail)
        ? null
        : AppTexts.translate('auth.error.invalid_email');
    final passwordError = s.invitePassword.length >= 6
        ? null
        : AppTexts.translate('auth.error.min_6');
    if (emailError != null || passwordError != null) {
      state = state.copyWith(
        inviteError: [emailError, passwordError].whereType<String>().join(' '),
      );
      return;
    }
    state = state.copyWith(loading: true, clearInviteError: true);
    try {
      final result = await ref.read(authRepositoryProvider).setResidentCredentials(
            resident.code ?? s.inviteCode,
            s.inviteEmail.trim().toLowerCase(),
            s.invitePassword,
          );
      _signIn(result);
    } catch (e) {
      state = state.copyWith(loading: false, inviteError: _messageOf(e));
    }
  }

  void logout() {
    ref.read(sessionRepositoryProvider).clear();
    state = state.copyWith(clearSession: true, clearError: true);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

String _messageOf(Object e) => _asAppException(e).userMessage();

AppException _asAppException(Object e) =>
    e is AppException ? e : AppException.unexpected(e);
