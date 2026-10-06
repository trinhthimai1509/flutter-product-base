import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/access_token_source.dart';
import 'auth_providers.dart';

/// Bridges the auth feature to `core/network` (dependency inversion).
class AuthTokenSource implements AccessTokenSource {
  AuthTokenSource(this._ref, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Ref _ref;
  final DateTime Function() _clock;

  @override
  Future<String?> accessToken() async {
    final repository = _ref.read(authRepositoryProvider);
    final session = repository.currentSession;
    if (session == null) return null;
    if (session.isExpired(_clock()) && session.canRefresh) {
      final refreshed = await refresh();
      return refreshed ? repository.currentSession?.accessToken : null;
    }
    return session.accessToken;
  }

  @override
  Future<bool> refresh() async {
    final result = await _ref.read(authRepositoryProvider).refreshSession();
    if (result.isOk) {
      _ref.read(authControllerProvider.notifier).syncFromRepository();
    }
    return result.isOk;
  }

  @override
  Future<void> onSessionExpired() =>
      _ref.read(authControllerProvider.notifier).handleSessionExpired();
}
