import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session.dart';

const _sessionKey = 'bf.resident.session.v1';

/// Persists the signed-in session (token + profile) across restarts.
///
/// The active session is also cached in memory ([current]) so the network
/// interceptor can read the bearer token synchronously. Persistence is
/// async, but the app loads the session before the first frame so [current]
/// is always correct by the time authenticated calls fire.
class SessionRepository {
  SessionRepository(this._prefs);

  final SharedPreferences _prefs;

  Session? _current;

  /// The active session, or null when signed out.
  Session? get current => _current;

  String? get accessToken => _current?.token;

  /// Multi-tenant scope for API queries (null when signed out).
  String? get activeDataOwnerId => _current?.activeDataOwnerId;

  /// Loads the persisted session (call once before the first frame).
  void loadFromStorage() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _current = Session.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt payload: treat as signed out.
      _prefs.remove(_sessionKey);
    }
  }

  /// Persists and activates [session].
  Future<void> signIn(Session session) async {
    _current = session;
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  /// Replaces the active profile (e.g. after a profile edit) and persists it.
  Future<void> updateProfile(UserProfile profile) async {
    final session = _current;
    if (session == null) return;
    final updated = Session(profile: profile, token: session.token);
    _current = updated;
    await _prefs.setString(_sessionKey, jsonEncode(updated.toJson()));
  }

  /// Clears the in-memory and persisted session.
  Future<void> clear() async {
    _current = null;
    await _prefs.remove(_sessionKey);
  }
}

/// Overridden in `main()` with a preloaded instance.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw UnimplementedError('Overridden in main().'),
);
