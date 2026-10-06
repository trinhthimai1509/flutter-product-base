import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Minimal logging facade. Swap the implementation (e.g. to forward errors to
/// Sentry/Crashlytics) by overriding `appLoggerProvider`.
///
/// Callers must never pass secrets; use `Redactor` for structured payloads.
abstract interface class AppLogger {
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
}

extension AppLoggerX on AppLogger {
  void debug(String message, {String? tag}) =>
      log(LogLevel.debug, message, tag: tag);
  void info(String message, {String? tag}) =>
      log(LogLevel.info, message, tag: tag);
  void warning(String message, {String? tag, Object? error}) =>
      log(LogLevel.warning, message, tag: tag, error: error);
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => log(
    LogLevel.error,
    message,
    tag: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Writes to `dart:developer` (visible in DevTools / IDE console).
class DeveloperLogger implements AppLogger {
  DeveloperLogger({
    this.minLevel = kReleaseMode ? LogLevel.warning : LogLevel.debug,
  });

  final LogLevel minLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;
    developer.log(
      message,
      name: tag ?? 'app',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Discards everything; handy in tests.
class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
