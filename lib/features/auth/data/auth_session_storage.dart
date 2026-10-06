import 'dart:convert';

import '../../../core/storage/secure_store.dart';
import '../domain/auth_session.dart';

/// Persists the session (including tokens) in [SecureStore] only.
class AuthSessionStorage {
  AuthSessionStorage(this._store);

  static const _key = 'auth.session';

  final SecureStore _store;

  Future<AuthSession?> read() async {
    final raw = await _store.read(_key);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupted or from an incompatible version: drop it.
      await clear();
      return null;
    }
  }

  Future<void> write(AuthSession session) =>
      _store.write(_key, jsonEncode(session.toJson()));

  Future<void> clear() => _store.delete(_key);
}
