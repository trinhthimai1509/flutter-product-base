import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_status.dart';
import '../../core/capabilities/capability_providers.dart';
import '../../core/navigation/route_access.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/chat/presentation/conversation_list_page.dart';
import '../../features/chat/presentation/conversation_page.dart';
import '../../features/home/presentation/capabilities_page.dart';
import '../../features/home/presentation/foundation_showcase_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/premium/presentation/premium_page.dart';
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

  final onboardingEnabled = ref.watch(onboardingEnabledProvider);
  final onboarding = ref.watch(onboardingControllerProvider);

  String? redirect(Uri location) {
    final needsOnboarding = onboardingEnabled && !onboarding.isCompleted;
    // Onboarding comes first, but only once the session is known, so the
    // splash still covers start-up.
    if (refresh.value != SessionStatus.unknown) {
      if (needsOnboarding && location.path != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (!needsOnboarding && location.path == AppRoutes.onboarding) {
        return guard.redirect(
          status: refresh.value,
          location: Uri(path: AppRoutes.splash),
        );
      }
    }
    return guard.redirect(status: refresh.value, location: location);
  }

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: Listenable.merge([refresh, onboarding]),
    redirect: (context, state) => redirect(state.uri),
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
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
          GoRoute(
            path: 'capabilities',
            builder: (context, state) => const CapabilitiesPage(),
          ),
          GoRoute(
            path: 'premium',
            builder: (context, state) => const PremiumPage(),
          ),
        ],
      ),
    ],
  );

  // Screen views use the route pattern (`/home/chat/:conversationId`), so
  // ids never reach analytics.
  final analytics = ref.watch(analyticsProvider);
  String? lastScreen;
  void logScreen() {
    final config = router.routerDelegate.currentConfiguration;
    // Pushed pages live in an ImperativeRouteMatch on top of the stack.
    final top = config.lastOrNull;
    final screen = top is ImperativeRouteMatch
        ? top.matches.fullPath
        : config.fullPath;
    if (screen.isEmpty || screen == lastScreen) return;
    lastScreen = screen;
    analytics.logScreenView(screen);
  }

  router.routerDelegate.addListener(logScreen);
  ref.onDispose(() {
    router.routerDelegate.removeListener(logScreen);
    router.dispose();
  });
  return router;
});
