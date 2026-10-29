/// Vendor-neutral crash reporting.
abstract interface class CrashReporter {
  /// Records a caught error. [fatal] marks errors that took the app down
  /// (e.g. from `PlatformDispatcher.onError`).
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Breadcrumb attached to the next report. Never log personal data.
  Future<void> log(String message);

  Future<void> setCustomKey(String key, Object value);
}

class NoOpCrashReporter implements CrashReporter {
  const NoOpCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// A recorded call to [RecordingCrashReporter.recordError].
class RecordedError {
  const RecordedError(this.error, this.stackTrace, this.reason, this.fatal);

  final Object error;
  final StackTrace? stackTrace;
  final String? reason;
  final bool fatal;
}

/// Keeps everything in memory. For tests.
class RecordingCrashReporter implements CrashReporter {
  final List<RecordedError> errors = [];
  final List<String> breadcrumbs = [];
  final Map<String, Object> customKeys = {};

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async => errors.add(RecordedError(error, stackTrace, reason, fatal));

  @override
  Future<void> log(String message) async => breadcrumbs.add(message);

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      customKeys[key] = value;
}
