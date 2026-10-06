import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../domain/auth_credential.dart';
import '../domain/auth_state.dart';
import 'auth_providers.dart';

/// Owns [AuthState]. Restores the session on creation, then reacts to
/// sign-in/sign-out/expiry. UI and router only read this state.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(Future.microtask(_restore));
    return const AuthUnknown();
  }

  Future<void> _restore() async {
    final result = await ref.read(authRepositoryProvider).restoreSession();
    if (!ref.mounted) return;
    final session = result.valueOrNull;
    state = session == null ? const Unauthenticated() : Authenticated(session);
  }

  /// Returns the result so the caller can show errors inline.
  Future<Result<void>> signIn(AuthCredential credential) async {
    final result = await ref.read(authRepositoryProvider).signIn(credential);
    if (!ref.mounted) return result;
    if (result case Ok(:final value)) state = Authenticated(value);
    return result;
  }

  Future<Result<void>> signInWithEmail(String email, String password) =>
      signIn(EmailPasswordCredential(email: email.trim(), password: password));

  Future<Result<void>> continueAsGuest() => signIn(const GuestCredential());

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (ref.mounted) state = const Unauthenticated();
  }

  /// Called by the network layer when refresh fails.
  Future<void> handleSessionExpired() => signOut();

  /// Called after a successful background refresh to keep state in sync.
  void syncFromRepository() {
    final session = ref.read(authRepositoryProvider).currentSession;
    state = session == null ? const Unauthenticated() : Authenticated(session);
  }
}
