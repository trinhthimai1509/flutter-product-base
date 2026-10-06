import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';
import '../../logging/redactor.dart';

/// Logs requests/responses with sensitive data redacted.
///
/// Bodies are only logged when [logBodies] is true (never in production, see
/// `AppConfig.fromEnvironment`). Headers and bodies pass through [Redactor].
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this.logger, {this.logBodies = false});

  static const _tag = 'http';
  static const _startKey = 'logStart';

  final AppLogger logger;
  final bool logBodies;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    final buffer = StringBuffer('--> ${options.method} ${options.uri.path}');
    if (logBodies) {
      buffer
        ..write(' headers=${Redactor.redactHeaders(options.headers)}')
        ..write(' body=${Redactor.redact(options.data)}');
    }
    logger.debug(buffer.toString(), tag: _tag);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final buffer = StringBuffer(
      '<-- ${response.statusCode} ${options.method} ${options.uri.path}'
      ' (${_elapsed(options)}ms)',
    );
    if (logBodies) buffer.write(' body=${Redactor.redact(response.data)}');
    logger.debug(buffer.toString(), tag: _tag);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    logger.warning(
      '<-- ${err.response?.statusCode ?? err.type.name} '
      '${options.method} ${options.uri.path} (${_elapsed(options)}ms)',
      tag: _tag,
    );
    handler.next(err);
  }

  int _elapsed(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is! DateTime) return -1;
    return DateTime.now().difference(start).inMilliseconds;
  }
}
