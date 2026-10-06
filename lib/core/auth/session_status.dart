/// Feature-agnostic session status consumed by routing and other core code.
enum SessionStatus {
  /// Restoration in progress.
  unknown,
  signedOut,

  /// Registered user or guest session.
  signedIn,
}
