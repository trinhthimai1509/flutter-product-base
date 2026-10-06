import 'package:flutter_project_base/app/router/app_routes.dart';
import 'package:flutter_project_base/core/auth/session_status.dart';
import 'package:flutter_project_base/core/navigation/route_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guard = RouteGuard(
    rules: AppRoutes.access,
    splashPath: AppRoutes.splash,
    signInPath: AppRoutes.signIn,
    homePath: AppRoutes.home,
  );

  String? redirect(SessionStatus status, String location) =>
      guard.redirect(status: status, location: Uri.parse(location));

  test('resolves access by most specific prefix', () {
    expect(guard.accessFor('/splash'), RouteAccess.public);
    expect(guard.accessFor('/sign-in'), RouteAccess.signedOutOnly);
    expect(guard.accessFor('/home/chat/abc'), RouteAccess.signedIn);
    expect(guard.accessFor('/unknown'), RouteAccess.signedIn);
  });

  test('waits on splash while session is unknown, keeping deep link', () {
    expect(redirect(SessionStatus.unknown, '/splash'), isNull);
    expect(
      redirect(SessionStatus.unknown, '/home/chat/support'),
      '/splash?from=%2Fhome%2Fchat%2Fsupport',
    );
  });

  test('leaves splash once status is known', () {
    expect(redirect(SessionStatus.signedIn, '/splash'), '/home');
    expect(
      redirect(SessionStatus.signedIn, '/splash?from=/home/chat/support'),
      '/home/chat/support',
    );
    expect(redirect(SessionStatus.signedOut, '/splash'), '/sign-in');
  });

  test('protects authenticated routes', () {
    expect(
      redirect(SessionStatus.signedOut, '/home/settings'),
      '/sign-in?from=%2Fhome%2Fsettings',
    );
    expect(redirect(SessionStatus.signedIn, '/home/settings'), isNull);
  });

  test('keeps signed-in users out of guest-only routes', () {
    expect(redirect(SessionStatus.signedIn, '/sign-in'), '/home');
    expect(
      redirect(SessionStatus.signedIn, '/sign-in?from=/home/profile'),
      '/home/profile',
    );
    expect(redirect(SessionStatus.signedOut, '/sign-in'), isNull);
  });

  test('ignores unsafe redirect targets', () {
    expect(
      redirect(SessionStatus.signedIn, '/sign-in?from=https://evil.com'),
      '/home',
    );
    expect(
      redirect(SessionStatus.signedIn, '/sign-in?from=//evil.com'),
      '/home',
    );
  });
}
