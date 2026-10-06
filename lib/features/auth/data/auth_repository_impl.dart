import 'dart:async';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/auth_credential.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_remote_data_source.dart';
import 'auth_session_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._storage,
    required this._logger,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthRemoteDataSource _remote;
  final AuthSessionStorage _storage;
  final AppLogger _logger;
  final DateTime Function() _clock;

  AuthSession? _session;

  /// Single-flight refresh: concurrent callers share one network call.
  Future<Result<AuthSession>>? _refreshing;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<Result<AuthSession?>> restoreSession() => guard(() async {
    final stored = await _storage.read();
    if (stored == null) return null;
    _session = stored;
    if (!stored.isExpired(_clock())) return stored;
    if (!stored.canRefresh) {
      await _clearLocal();
      return null;
    }
    switch (await refreshSession()) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        // Offline: keep the stored session so the app opens; requests will
        // retry refresh on 401. Rejected refresh: sign out locally.
        if (failure is NetworkFailure) return stored;
        await _clearLocal();
        return null;
    }
  });

  @override
  Future<Result<AuthSession>> signIn(AuthCredential credential) =>
      guard(() async {
        final session = await _remote.signIn(credential);
        await _storage.write(session);
        _session = session;
        return session;
      });

  @override
  Future<Result<AuthSession>> refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<Result<AuthSession>> _doRefresh() => guard(() async {
    final current = _session ?? await _storage.read();
    final token = current?.refreshToken;
    if (current == null || token == null || token.isEmpty) {
      throw const UnauthorizedFailure('No refresh token');
    }
    final refreshed = await _remote.refresh(token);
    // Keep profile data if the refresh response omits it.
    final merged = refreshed.copyWith(
      user: refreshed.user.email == null && refreshed.user.id == current.user.id
          ? current.user
          : refreshed.user,
    );
    await _storage.write(merged);
    _session = merged;
    return merged;
  });

  @override
  Future<void> signOut() async {
    final session = _session;
    await _clearLocal();
    if (session == null) return;
    // Best effort: local sign-out must succeed even if the server is down.
    unawaited(
      Future(() => _remote.signOut(session)).catchError((Object error) {
        _logger.warning('Remote sign-out failed', tag: 'auth', error: error);
      }),
    );
  }

  Future<void> _clearLocal() async {
    _session = null;
    await _storage.clear();
  }
}
