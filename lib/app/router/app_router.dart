import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_status.dart';
import '../../core/navigation/route_access.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/chat/presentation/conversation_list_page.dart';
import '../../features/chat/presentation/conversation_page.dart';
import '../../features/home/presentation/foundation_showcase_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../pages.dart';
import 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Session status for routing, decoupled from the auth feature's types.
final sessionStatusProvider = Provider<SessionStatus>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.status)),
);

final routerProvider = Provider<GoRouter>((ref) {
  const guard = RouteGuard(
    rules: AppRoutes.access,
    splashPath: AppRoutes.splash,
    signInPath: AppRoutes.signIn,
    homePath: AppRoutes.home,
  );

  // Re-evaluate redirects whenever the session status changes, without
  // rebuilding the router (which would reset navigation state).
  final refresh = ValueNotifier<SessionStatus>(ref.read(sessionStatusProvider));
  ref
    ..listen(sessionStatusProvider, (_, next) => refresh.value = next)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) =>
        guard.redirect(status: refresh.value, location: state.uri),
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) => const ConversationListPage(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (context, state) => ConversationPage(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: 'showcase',
            builder: (context, state) => const FoundationShowcasePage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
