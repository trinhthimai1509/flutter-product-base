import 'package:flutter_project_base/core/capabilities/capability_providers.dart';
import 'package:flutter_project_base/core/logging/app_logger.dart';
import 'package:flutter_project_base/core/storage/key_value_store.dart';
import 'package:flutter_project_base/features/onboarding/application/onboarding_providers.dart';
import 'package:flutter_project_base/shared/utils/external_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_common/pb_common.dart';

class _RecordingLogger implements AppLogger {
  final levels = <LogLevel>[];

  @override
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => levels.add(level);
}

void main() {
  test('AppPbLogger maps every level to the app logger', () {
    final logger = _RecordingLogger();
    AppPbLogger(logger)
      ..debug('d')
      ..info('i')
      ..warning('w')
      ..error('e');
    expect(logger.levels, LogLevel.values);
  });

  test('KeyValueOwnershipCache round-trips ownership', () async {
    final store = InMemoryKeyValueStore();
    final cache = KeyValueOwnershipCache(store);
    expect(cache.owned, isNull);
    await cache.save(true);
    expect(KeyValueOwnershipCache(store).owned, isTrue);
  });

  test('KeyValueOnboardingStore round-trips completion', () async {
    final store = InMemoryKeyValueStore();
    final onboarding = KeyValueOnboardingStore(store);
    expect(onboarding.isCompleted, isFalse);
    await onboarding.setCompleted(true);
    expect(KeyValueOnboardingStore(store).isCompleted, isTrue);
  });

  test('openUrl only accepts http(s) URLs with a host', () {
    bool ok(String url) => PlatformExternalActions.isWebUrl(Uri.parse(url));
    expect(ok('https://example.com/privacy'), isTrue);
    expect(ok('http://example.com'), isTrue);
    expect(ok('intent://scan/#Intent;scheme=zxing;end'), isFalse);
    expect(ok('file:///etc/passwd'), isFalse);
    expect(ok('javascript:alert(1)'), isFalse);
    expect(ok('https:///no-host'), isFalse);
  });
}
