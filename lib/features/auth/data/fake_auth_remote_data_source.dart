import '../../../core/error/app_failure.dart';
import '../domain/auth_credential.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import 'auth_remote_data_source.dart';

/// In-process fake used when `AppConfig.useFakeBackend` is true (demo/dev)
/// and in tests. Accepts any well-formed email with a 6+ char password.
/// Issues opaque fake tokens; nothing leaves the device.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource({
    this.latency = const Duration(milliseconds: 400),
    this.tokenLifetime = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration latency;
  final Duration tokenLifetime;
  final DateTime Function() _clock;
  int _issued = 0;

  @override
  Future<AuthSession> signIn(AuthCredential credential) async {
    await Future<void>.delayed(latency);
    return switch (credential) {
      GuestCredential() => _issue(
        AuthUser(
          id: 'guest-${_clock().millisecondsSinceEpoch}',
          isAnonymous: true,
        ),
      ),
      EmailPasswordCredential(:final email, :final password) =>
        password.length < 6
            ? throw const UnauthorizedFailure('Invalid credentials')
            : _issue(
                AuthUser(
                  id: 'user-${email.toLowerCase().hashCode.abs()}',
                  email: email,
                  displayName: email.split('@').first,
                ),
              ),
      OAuthCredential(:final provider) => throw UnknownFailure(
        'OAuth provider "$provider" is not configured in the fake backend',
      ),
    };
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    await Future<void>.delayed(latency);
    if (!refreshToken.startsWith('fake-refresh-')) {
      throw const UnauthorizedFailure('Invalid refresh token');
    }
    final userJson = refreshToken.substring('fake-refresh-'.length);
    // The fake encodes the user id in the refresh token.
    return _issue(AuthUser(id: userJson.split('|').first));
  }

  @override
  Future<void> signOut(AuthSession session) async {}

  AuthSession _issue(AuthUser user) {
    _issued++;
    return AuthSession(
      user: user,
      accessToken: 'fake-access-$_issued',
      refreshToken: 'fake-refresh-${user.id}|$_issued',
      expiresAt: _clock().add(tokenLifetime),
    );
  }
}
