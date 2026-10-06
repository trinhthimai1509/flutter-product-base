/// Contract between the network layer and whichever feature owns the session.
///
/// `core/network` depends on this interface only; `features/auth` provides
/// the implementation. This keeps core independent of any feature.
abstract interface class AccessTokenSource {
  /// Current access token, or null when there is no authenticated session.
  Future<String?> accessToken();

  /// Attempts to refresh the session. Returns true when a new access token
  /// is available.
  Future<bool> refresh();

  /// Called when the session can no longer be recovered (refresh failed).
  Future<void> onSessionExpired();
}

/// No session at all; used until a real source is wired in, and in tests.
class NoAccessTokenSource implements AccessTokenSource {
  const NoAccessTokenSource();

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> refresh() async => false;

  @override
  Future<void> onSessionExpired() async {}
}
