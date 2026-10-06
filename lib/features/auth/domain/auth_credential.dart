/// Ways to start a session. Add new sign-in methods as subclasses; the
/// repository/data source decide how to exchange them for an `AuthSession`.
sealed class AuthCredential {
  const AuthCredential();
}

class GuestCredential extends AuthCredential {
  const GuestCredential();
}

class EmailPasswordCredential extends AuthCredential {
  const EmailPasswordCredential({required this.email, required this.password});

  final String email;
  final String password;

  @override
  String toString() => 'EmailPasswordCredential($email)';
}

/// Extension point for Google/Apple/Facebook/etc. The platform SDK obtains
/// [token] (ID token or auth code); the backend verifies it.
/// No vendor SDK is bundled in the base.
class OAuthCredential extends AuthCredential {
  const OAuthCredential({required this.provider, required this.token});

  /// Provider identifier understood by your backend, e.g. `google`.
  final String provider;
  final String token;

  @override
  String toString() => 'OAuthCredential($provider)';
}
