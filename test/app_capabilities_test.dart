import 'package:flutter/material.dart';
import 'package:flutter_project_base/app/app.dart';
import 'package:flutter_project_base/core/capabilities/capability_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_connectivity/pb_connectivity.dart';
import 'package:pb_notifications/pb_notifications.dart';
import 'package:pb_onboarding/pb_onboarding.dart';
import 'package:pb_telemetry/pb_telemetry.dart';

import 'helpers/test_helpers.dart';

/// End-to-end checks of the capability packages wired into the real app:
/// onboarding, paywall, capabilities demo, offline banner, notification
/// taps and screen analytics. Every package runs on its fake.
void main() {
  late RecordingAnalytics analytics;
  late FakeLocalNotifications notifications;
  late FakeNetworkMonitor network;

  setUp(() {
    analytics = RecordingAnalytics();
    notifications = FakeLocalNotifications();
    network = FakeNetworkMonitor();
  });

  tearDown(() async {
    await notifications.dispose();
    await network.dispose();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    OnboardingCompletionStore? onboardingStore,
  }) async {
    tester.view.physicalSize = const Size(1260, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          ...baseTestOverrides(
            onboardingStore: onboardingStore,
            networkMonitor: network,
            localNotifications: notifications,
            telemetry: Telemetry(
              analytics: analytics,
              crashReporter: const NoOpCrashReporter(),
              backendName: 'recording',
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterAsGuest(WidgetTester tester) async {
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows onboarding; skipping persists it', (
    tester,
  ) async {
    final store = InMemoryOnboardingCompletionStore();
    await pumpApp(tester, onboardingStore: store);

    expect(find.text('A foundation, not a product'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(store.isCompleted, isTrue);
    expect(find.text('Welcome'), findsOneWidget, reason: 'sign-in page');
  });

  testWidgets('settings → paywall → buy → Pro is active', (tester) async {
    await pumpApp(tester);
    await enterAsGuest(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Go Pro'), findsOneWidget);

    await tester.tap(find.text(r'Get Pro for $4.99'));
    await tester.pumpAndSettle();
    expect(find.text('You have Pro. Thank you!'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Pro is active'), findsOneWidget);
  });

  testWidgets('capabilities demo logs events and schedules reminders', (
    tester,
  ) async {
    await pumpApp(tester);
    await enterAsGuest(tester);
    await tester.tap(find.text('Capabilities'));
    await tester.pumpAndSettle();

    expect(find.text('Backend: recording'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(
      notifications.channels.single.id,
      AppNotificationChannels.reminders,
      reason: 'channels are created at start-up',
    );

    await tester.tap(find.text('Log a test event'));
    await tester.pumpAndSettle();
    expect(analytics.events.single.name, 'demo_button');

    await tester.scrollUntilVisible(find.text('Remind me in 10 seconds'), 200);
    await tester.tap(find.text('Remind me in 10 seconds'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled.keys, ['demo-reminder']);
  });

  testWidgets('offline banner follows connectivity', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining("You're offline"), findsNothing);

    network.online = false;
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);

    network.online = true;
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsNothing);
  });

  testWidgets('tapping a notification opens its in-app location', (
    tester,
  ) async {
    await pumpApp(tester);
    await enterAsGuest(tester);

    notifications.simulateOpen('/home/capabilities');
    await tester.pumpAndSettle();
    expect(find.text('Log a test event'), findsOneWidget);

    notifications.simulateOpen('https://evil.example');
    await tester.pumpAndSettle();
    expect(find.text('Log a test event'), findsOneWidget, reason: 'ignored');
  });

  testWidgets('screen views use route patterns, never ids', (tester) async {
    await pumpApp(tester);
    await enterAsGuest(tester);
    await tester.tap(find.text('Chat demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mock Assistant'));
    await tester.pumpAndSettle();

    expect(analytics.screens, contains('/home/chat/:conversationId'));
    expect(analytics.screens.where((s) => s.contains('assistant')), isEmpty);
  });
}
