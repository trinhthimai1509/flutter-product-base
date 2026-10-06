import 'package:dio/dio.dart';

import '../auth/access_token_source.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Builds configured [Dio] instances.
///
/// No automatic retry for failed requests is installed: blind retries of
/// non-idempotent calls cause duplicate side effects. Add a retry interceptor
/// per use case (e.g. idempotent GETs) when a real need appears.
abstract final class DioFactory {
  static BaseOptions baseOptions(AppConfig config) => BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    sendTimeout: config.receiveTimeout,
    headers: const {'Accept': 'application/json'},
    contentType: Headers.jsonContentType,
  );

  /// Client without auth handling, for auth endpoints (login/refresh) and
  /// public APIs. Using it for refresh avoids recursive 401 handling.
  static Dio createPublic(AppConfig config, AppLogger logger) {
    final dio = Dio(baseOptions(config));
    _addLogging(dio, config, logger);
    return dio;
  }

  /// Client that injects the bearer token and refreshes on 401.
  static Dio createAuthenticated(
    AppConfig config,
    AppLogger logger,
    AccessTokenSource tokenSource,
  ) {
    final dio = Dio(baseOptions(config));
    // A separate client replays requests after refresh so the replay does not
    // re-enter the queued auth interceptor (which would deadlock).
    final retryClient = Dio(baseOptions(config));
    _addLogging(retryClient, config, logger);
    dio.interceptors.add(
      AuthInterceptor(tokenSource: tokenSource, retryClient: retryClient),
    );
    _addLogging(dio, config, logger);
    return dio;
  }

  static void _addLogging(Dio dio, AppConfig config, AppLogger logger) {
    if (!config.enableNetworkLogs) return;
    dio.interceptors.add(
      LoggingInterceptor(logger, logBodies: config.logNetworkBodies),
    );
  }
}
