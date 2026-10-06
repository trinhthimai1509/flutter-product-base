import 'package:dio/dio.dart';

import '../../auth/access_token_source.dart';

/// Injects `Authorization: Bearer <token>` and transparently refreshes the
/// session once on HTTP 401.
///
/// Extends [QueuedInterceptor] so concurrent 401s trigger a single refresh.
/// Requests can opt out with `Options(extra: {AuthInterceptor.skipAuth: true})`.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenSource, required this.retryClient});

  static const skipAuth = 'skipAuth';
  static const _retried = 'authRetried';

  final AccessTokenSource tokenSource;

  /// Client used to replay the original request after a refresh.
  final Dio retryClient;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
      final token = await tokenSource.accessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized ||
        options.extra[skipAuth] == true ||
        options.extra[_retried] == true) {
      return handler.next(err);
    }

    final refreshed = await tokenSource.refresh();
    if (!refreshed) {
      await tokenSource.onSessionExpired();
      return handler.next(err);
    }

    try {
      final token = await tokenSource.accessToken();
      options.extra[_retried] = true;
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      final response = await retryClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
