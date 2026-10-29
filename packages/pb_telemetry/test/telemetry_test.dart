import 'package:flutter_test/flutter_test.dart';
import 'package:pb_telemetry/pb_telemetry.dart';

void main() {
  test('noOp telemetry reports no backend', () {
    expect(Telemetry.noOp.isNoOp, isTrue);
    expect(Telemetry.noOp.analytics, isA<NoOpAnalytics>());
  });

  test('RecordingAnalytics keeps screens, events and user id', () async {
    final analytics = RecordingAnalytics();
    await analytics.logScreenView('home');
    await analytics.logEvent(const AnalyticsEvent('tap', {'id': 1}));
    await analytics.setUserId('u1');

    expect(analytics.screens, ['home']);
    expect(analytics.events.single.name, 'tap');
    expect(analytics.events.single.params, {'id': 1});
    expect(analytics.userId, 'u1');
  });

  test('RecordingCrashReporter keeps errors, breadcrumbs and keys', () async {
    final reporter = RecordingCrashReporter();
    await reporter.recordError(StateError('x'), null, fatal: true);
    await reporter.log('opened chat');
    await reporter.setCustomKey('env', 'dev');

    expect(reporter.errors.single.fatal, isTrue);
    expect(reporter.breadcrumbs, ['opened chat']);
    expect(reporter.customKeys, {'env': 'dev'});
  });
}
