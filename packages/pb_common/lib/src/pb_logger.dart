/// Severity of a [PbLogger] entry.
enum PbLogLevel { debug, info, warning, error }

/// Logging contract every Product Base package logs through.
///
/// Packages never pick a logging backend. The app adapts its own logger to
/// this interface once, in its composition root, and passes it in.
/// Callers must never pass secrets, tokens or personal data.
abstract interface class PbLogger {
  void log(
    PbLogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
}

extension PbLoggerX on PbLogger {
  void debug(String message, {String? tag}) =>
      log(PbLogLevel.debug, message, tag: tag);
  void info(String message, {String? tag}) =>
      log(PbLogLevel.info, message, tag: tag);
  void warning(String message, {String? tag, Object? error}) =>
      log(PbLogLevel.warning, message, tag: tag, error: error);
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    PbLogLevel.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Discards everything. The default for packages when no logger is given.
class NoOpPbLogger implements PbLogger {
  const NoOpPbLogger();

  @override
  void log(
    PbLogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
