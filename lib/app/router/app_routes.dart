import '../../core/navigation/route_access.dart';

/// Route paths in one place. Use these constants instead of string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const home = '/home';
  static const chat = '/home/chat';
  static const settings = '/home/settings';
  static const profile = '/home/profile';
  static const showcase = '/home/showcase';

  static String conversation(String id) => '$chat/${Uri.encodeComponent(id)}';

  /// Access rules by path prefix; the most specific prefix wins.
  /// Unlisted paths default to [RouteAccess.signedIn].
  static const access = <String, RouteAccess>{
    splash: RouteAccess.public,
    signIn: RouteAccess.signedOutOnly,
    home: RouteAccess.signedIn,
  };
}
