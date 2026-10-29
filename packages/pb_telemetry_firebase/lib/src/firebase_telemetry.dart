import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:pb_common/pb_common.dart';
import 'package:pb_telemetry/pb_telemetry.dart';

/// The only place in the workspace that sees a Firebase type.
abstract final class FirebaseTelemetry {
  /// Initializes Firebase and returns Firebase-backed telemetry.
  ///
  /// Never throws: when Firebase is not configured (no
  /// `google-services.json` / `GoogleService-Info.plist`, or [options] for
  /// web) it logs and returns [Telemetry.noOp], so a fresh clone still runs.
  ///
  /// [collectionEnabled] lets debug builds keep Crashlytics quiet.
  static Future<Telemetry> initialize({
    FirebaseOptions? options,
    bool collectionEnabled = !kDebugMode,
    PbLogger logger = const NoOpPbLogger(),
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(collectionEnabled);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        collectionEnabled,
      );
      logger.info('Firebase telemetry ready', tag: 'telemetry');
      return Telemetry(
        analytics: FirebaseAnalyticsClient(FirebaseAnalytics.instance),
        crashReporter: CrashlyticsReporter(crashlytics),
        backendName: 'firebase',
      );
    } on Object catch (error) {
      logger.warning(
        'Firebase not configured; telemetry is a no-op',
        tag: 'telemetry',
        error: error,
      );
      return Telemetry.noOp;
    }
  }
}

class FirebaseAnalyticsClient implements Analytics {
  FirebaseAnalyticsClient(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  @override
  Future<void> logEvent(AnalyticsEvent event) => _analytics.logEvent(
    name: event.name,
    parameters: event.params.isEmpty ? null : event.params,
  );

  @override
  Future<void> setUserId(String? id) => _analytics.setUserId(id: id);
}

class CrashlyticsReporter implements CrashReporter {
  CrashlyticsReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) =>
      _crashlytics.recordError(error, stackTrace, reason: reason, fatal: fatal);

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);
}
