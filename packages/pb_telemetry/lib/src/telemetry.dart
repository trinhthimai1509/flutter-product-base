import 'analytics.dart';
import 'crash_reporter.dart';

/// The pair of telemetry services an app wires once at start-up.
class Telemetry {
  const Telemetry({
    required this.analytics,
    required this.crashReporter,
    this.backendName = 'none',
  });

  /// Both services discard everything.
  static const noOp = Telemetry(
    analytics: NoOpAnalytics(),
    crashReporter: NoOpCrashReporter(),
  );

  final Analytics analytics;
  final CrashReporter crashReporter;

  /// Human-readable backend name, e.g. `firebase` or `none` (shown in the
  /// demo and useful in logs).
  final String backendName;

  bool get isNoOp => backendName == 'none';
}
