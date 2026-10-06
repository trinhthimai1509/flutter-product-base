import 'package:equatable/equatable.dart';

import '../../../core/auth/session_status.dart';
import 'auth_session.dart';
import 'auth_user.dart';

/// Observable authentication state for the UI and router.
sealed class AuthState extends Equatable {
  const AuthState();

  SessionStatus get status => switch (this) {
    AuthUnknown() => SessionStatus.unknown,
    Unauthenticated() => SessionStatus.signedOut,
    Authenticated() => SessionStatus.signedIn,
  };

  AuthSession? get session => switch (this) {
    Authenticated(:final session) => session,
    _ => null,
  };

  AuthUser? get user => session?.user;

  @override
  List<Object?> get props => [];
}

/// Session restoration has not finished yet (splash).
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Signed in, either as a registered user or as a guest
/// (check `session.isGuest`).
class Authenticated extends AuthState {
  const Authenticated(this.session);

  @override
  final AuthSession session;

  @override
  List<Object?> get props => [session];
}
