import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart' show DynamicColorPlugin;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pb_ads/pb_ads.dart';
import 'package:pb_billing/pb_billing.dart';
import 'package:pb_common/pb_common.dart';
import 'package:pb_connectivity/pb_connectivity.dart';
import 'package:pb_notifications/pb_notifications.dart';
import 'package:pb_review/pb_review.dart';
import 'package:pb_telemetry/pb_telemetry.dart';

import '../../shared/utils/external_actions.dart';
import '../di/core_providers.dart';
import '../logging/app_logger.dart';
import '../storage/key_value_store.dart';

/// Riverpod wiring for the opt-in capability packages in `packages/`.
///
/// Each package is plain Dart (no Riverpod); this file is the only place
/// that knows which implementation the app uses. To drop a capability,
/// delete its providers here and the package from pubspec.yaml.
/// Tests override these with the packages' fakes (see test_helpers.dart).

/// The app logger, as the logging contract the packages accept.
final pbLoggerProvider = Provider<PbLogger>(
  (ref) => AppPbLogger(ref.watch(appLoggerProvider)),
);

class AppPbLogger implements PbLogger {
  const AppPbLogger(this._logger);

  final AppLogger _logger;

  @override
  void log(
    PbLogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => _logger.log(
    switch (level) {
      PbLogLevel.debug => LogLevel.debug,
      PbLogLevel.info => LogLevel.info,
      PbLogLevel.warning => LogLevel.warning,
      PbLogLevel.error => LogLevel.error,
    },
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

// --- Telemetry (pb_telemetry, pb_telemetry_firebase) ----------------------

/// No-op by default; bootstrap overrides it with Firebase when
/// `ENABLE_FIREBASE` is on and Firebase is configured.
final telemetryProvider = Provider<Telemetry>((ref) => Telemetry.noOp);

final analyticsProvider = Provider<Analytics>(
  (ref) => ref.watch(telemetryProvider).analytics,
);

final crashReporterProvider = Provider<CrashReporter>(
  (ref) => ref.watch(telemetryProvider).crashReporter,
);

// --- Connectivity (pb_connectivity) ---------------------------------------

final networkMonitorProvider = Provider<NetworkMonitor>(
  (ref) => ConnectivityPlusNetworkMonitor(),
);

/// Current online state; starts optimistic so nothing flashes "offline".
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final monitor = ref.watch(networkMonitorProvider);
  yield await monitor.isOnline();
  yield* monitor.onStatusChange;
});

// --- Notifications (pb_notifications) -------------------------------------

/// Notification channels this app creates at start-up (CapabilitiesScope).
abstract final class AppNotificationChannels {
  static const reminders = 'reminders';
}

final localNotificationsProvider = Provider<LocalNotifications>((ref) {
  if (!_isMobile) return FakeLocalNotifications();
  final notifications = PluginLocalNotifications(
    logger: ref.watch(pbLoggerProvider),
  );
  ref.onDispose(notifications.dispose);
  return notifications;
});

// --- Review (pb_review) ---------------------------------------------------

final appReviewManagerProvider = Provider<AppReviewManager>(
  (ref) => InAppReviewManager(
    appStoreId: ref.watch(appConfigProvider).appStoreId,
    logger: ref.watch(pbLoggerProvider),
  ),
);

// --- Billing (pb_billing) -------------------------------------------------

/// Remembers ownership across launches (UX only; see [OwnershipCache]).
class KeyValueOwnershipCache implements OwnershipCache {
  KeyValueOwnershipCache(this._store);

  static const key = 'billing.proOwned';
  final KeyValueStore _store;

  @override
  bool? get owned => _store.getBool(key);

  @override
  Future<void> save(bool owned) => _store.setBool(key, owned);
}

final billingManagerProvider = Provider<BillingManager>((ref) {
  final config = ref.watch(appConfigProvider);
  final BillingManager manager = config.useFakeBilling || !_isMobile
      ? FakeBillingManager()
      : StoreBillingManager(
          config: BillingConfig(proProductId: config.proProductId),
          cache: KeyValueOwnershipCache(ref.watch(keyValueStoreProvider)),
          logger: ref.watch(pbLoggerProvider),
        );
  unawaited(manager.initialize());
  ref.onDispose(manager.dispose);
  return manager;
});

/// "Is the user premium?" for every consumer (ads, features). Override with
/// `PremiumState.alwaysFree` in an app that sells nothing.
final premiumStateProvider = Provider<PremiumState>((ref) {
  final state = BillingPremiumState(ref.watch(billingManagerProvider));
  ref.onDispose(state.dispose);
  return state;
});

// --- Ads (pb_ads) ---------------------------------------------------------

/// Google test units. Replace with your own units for production builds
/// (keep test units for every other environment).
final adsConfigProvider = Provider<AdsConfig>(
  (ref) =>
      AdsConfig.testAds(adsEnabled: ref.watch(appConfigProvider).adsEnabled),
);

final adsControllerProvider = Provider<AdsController>((ref) {
  final controller = GoogleAdsController(
    config: ref.watch(adsConfigProvider),
    premiumState: ref.watch(premiumStateProvider),
    logger: ref.watch(pbLoggerProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

// --- External actions (share, links) ----------------------------------------

final externalActionsProvider = Provider<ExternalActions>(
  (ref) => const PlatformExternalActions(),
);

// --- Dynamic color (dynamic_color) ------------------------------------------

/// The wallpaper's primary color on Android 12+, null elsewhere. The app
/// derives its schemes from it with `ColorScheme.fromSeed` (the same
/// tonal-spot algorithm Android uses), which keeps every color in sync with
/// the Flutter SDK's `ColorScheme` type.
final dynamicSeedColorProvider = FutureProvider<Color?>((ref) async {
  try {
    final palette = await DynamicColorPlugin.getCorePalette();
    return palette == null ? null : Color(palette.primary.get(40));
  } on Object {
    return null;
  }
});

/// Settings hides the dynamic color switch where it would do nothing.
final dynamicColorSupportedProvider = Provider<bool>(
  (ref) => ref.watch(dynamicSeedColorProvider).value != null,
);
