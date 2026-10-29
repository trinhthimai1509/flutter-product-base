/// A product-defined analytics event. The base ships no event taxonomy:
/// name your own events (snake_case, ≤ 40 chars works with every vendor).
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.params = const {}]);

  final String name;

  /// Values must be `String`, `num` or `bool`; vendors drop anything else.
  final Map<String, Object> params;

  @override
  String toString() => 'AnalyticsEvent($name, $params)';
}

/// Vendor-neutral analytics. Product code logs through this; only an
/// implementation package (e.g. pb_telemetry_firebase) sees a vendor type.
abstract interface class Analytics {
  Future<void> logScreenView(String screenName);
  Future<void> logEvent(AnalyticsEvent event);

  /// Pass null to clear (e.g. on sign-out). Never pass an email or a name.
  Future<void> setUserId(String? id);
}

class NoOpAnalytics implements Analytics {
  const NoOpAnalytics();

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

/// Keeps everything in memory. For tests and the demo's event log.
class RecordingAnalytics implements Analytics {
  final List<AnalyticsEvent> events = [];
  final List<String> screens = [];
  String? userId;

  @override
  Future<void> logScreenView(String screenName) async =>
      screens.add(screenName);

  @override
  Future<void> logEvent(AnalyticsEvent event) async => events.add(event);

  @override
  Future<void> setUserId(String? id) async => userId = id;
}
