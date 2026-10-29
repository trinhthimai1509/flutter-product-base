import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_project_base/core/capabilities/capability_providers.dart';
import 'package:flutter_project_base/core/config/app_config.dart';
import 'package:flutter_project_base/core/di/core_providers.dart';
import 'package:flutter_project_base/core/localization/l10n.dart';
import 'package:flutter_project_base/core/logging/app_logger.dart';
import 'package:flutter_project_base/core/storage/key_value_store.dart';
import 'package:flutter_project_base/core/storage/secure_store.dart';
import 'package:flutter_project_base/core/theme/app_theme.dart';
import 'package:flutter_project_base/features/auth/application/auth_providers.dart';
import 'package:flutter_project_base/features/auth/data/fake_auth_remote_data_source.dart';
import 'package:flutter_project_base/features/onboarding/application/onboarding_providers.dart';
import 'package:flutter_project_base/shared/utils/external_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ads/pb_ads.dart';
import 'package:pb_billing/pb_billing.dart';
import 'package:pb_connectivity/pb_connectivity.dart';
import 'package:pb_notifications/pb_notifications.dart';
import 'package:pb_onboarding/pb_onboarding.dart';
import 'package:pb_review/pb_review.dart';
import 'package:pb_telemetry/pb_telemetry.dart';

const testConfig = AppConfig(
  environment: AppEnvironment.development,
  appName: 'Test App',
  apiBaseUrl: 'https://api.test',
  useFakeBackend: true,
);

/// Records share/open calls instead of leaving the app.
class FakeExternalActions implements ExternalActions {
  final shared = <String>[];
  final opened = <String>[];

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    shared.add(text);
    return true;
  }

  @override
  Future<bool> openUrl(String url) async {
    opened.add(url);
    return true;
  }
}

/// Overrides that make the whole app run in-memory with no delays, with
/// every capability package replaced by its fake (no plugins in tests).
List<Override> baseTestOverrides({
  KeyValueStore? keyValueStore,
  SecureStore? secureStore,
  bool onboardingCompleted = true,
  OnboardingCompletionStore? onboardingStore,
  NetworkMonitor? networkMonitor,
  LocalNotifications? localNotifications,
  Telemetry? telemetry,
}) => [
  appConfigProvider.overrideWithValue(testConfig),
  appLoggerProvider.overrideWithValue(const SilentLogger()),
  keyValueStoreProvider.overrideWithValue(
    keyValueStore ?? InMemoryKeyValueStore(),
  ),
  secureStoreProvider.overrideWithValue(secureStore ?? InMemorySecureStore()),
  authRemoteDataSourceProvider.overrideWithValue(
    FakeAuthRemoteDataSource(latency: Duration.zero),
  ),
  onboardingStoreProvider.overrideWithValue(
    onboardingStore ??
        InMemoryOnboardingCompletionStore(isCompleted: onboardingCompleted),
  ),
  networkMonitorProvider.overrideWithValue(
    networkMonitor ?? FakeNetworkMonitor(),
  ),
  localNotificationsProvider.overrideWithValue(
    localNotifications ?? FakeLocalNotifications(),
  ),
  telemetryProvider.overrideWithValue(telemetry ?? Telemetry.noOp),
  appReviewManagerProvider.overrideWithValue(FakeAppReviewManager()),
  billingManagerProvider.overrideWith((ref) {
    final billing = FakeBillingManager(latency: Duration.zero);
    ref.onDispose(billing.dispose);
    return billing..initialize();
  }),
  adsControllerProvider.overrideWith((ref) {
    final ads = FakeAdsController(available: false);
    ref.onDispose(ads.dispose);
    return ads;
  }),
  externalActionsProvider.overrideWithValue(FakeExternalActions()),
  dynamicSeedColorProvider.overrideWith((ref) async => null),
];

/// Disables Riverpod's automatic retry so failing providers settle in tests.
Duration? noRetry(int retryCount, Object error) => null;

ProviderContainer createTestContainer({
  KeyValueStore? keyValueStore,
  SecureStore? secureStore,
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      ...baseTestOverrides(
        keyValueStore: keyValueStore,
        secureStore: secureStore,
      ),
      ...overrides,
    ],
    retry: noRetry,
  );
  addTearDown(container.dispose);
  return container;
}

/// Wraps [child] with theme + localization for widget tests.
Widget testApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: const AppTheme().light,
    locale: locale,
    supportedLocales: AppLocales.supported,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}
