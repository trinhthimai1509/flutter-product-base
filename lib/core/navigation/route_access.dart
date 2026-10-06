import '../auth/session_status.dart';

/// Who may open a route.
enum RouteAccess {
  /// Anyone, any time (splash, legal pages, public deep links).
  public,

  /// Only without a session (sign-in, onboarding). "Guest route".
  signedOutOnly,

  /// Requires a session (registered or guest). "Authenticated route".
  signedIn,
}

/// Pure, feature-agnostic redirect logic used by the router.
///
/// Returns the location to redirect to, or null to allow navigation.
/// `from` query parameter preserves deep links across sign-in.
class RouteGuard {
  const RouteGuard({
    required this.rules,
    required this.splashPath,
    required this.signInPath,
    required this.homePath,
    this.defaultAccess = RouteAccess.signedIn,
  });

  final Map<String, RouteAccess> rules;
  final String splashPath;
  final String signInPath;
  final String homePath;
  final RouteAccess defaultAccess;

  RouteAccess accessFor(String path) {
    String? best;
    for (final prefix in rules.keys) {
      final matches = path == prefix || path.startsWith('$prefix/');
      if (matches && (best == null || prefix.length > best.length)) {
        best = prefix;
      }
    }
    return best == null ? defaultAccess : rules[best]!;
  }

  String? redirect({required SessionStatus status, required Uri location}) {
    final path = location.path;
    final from = location.queryParameters['from'];

    if (status == SessionStatus.unknown) {
      // Wait on splash, remembering where the user wanted to go.
      if (path == splashPath) return null;
      return _withFrom(splashPath, location.toString());
    }

    if (path == splashPath) {
      if (status == SessionStatus.signedIn) return _safe(from) ?? homePath;
      return _withFrom(signInPath, from);
    }

    switch (accessFor(path)) {
      case RouteAccess.public:
        return null;
      case RouteAccess.signedOutOnly:
        return status == SessionStatus.signedIn
            ? _safe(from) ?? homePath
            : null;
      case RouteAccess.signedIn:
        return status == SessionStatus.signedIn
            ? null
            : _withFrom(signInPath, location.toString());
    }
  }

  String _withFrom(String path, String? from) {
    final target = _safe(from);
    if (target == null || target == homePath) return path;
    return Uri(path: path, queryParameters: {'from': target}).toString();
  }

  /// Only allow in-app relative locations (prevents open redirects).
  String? _safe(String? from) {
    if (from == null || from.isEmpty) return null;
    if (!from.startsWith('/') || from.startsWith('//')) return null;
    final path = Uri.tryParse(from)?.path;
    if (path == null || path == splashPath || path == signInPath) return null;
    return from;
  }
}
