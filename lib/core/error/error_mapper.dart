import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'app_failure.dart';

/// Converts arbitrary errors into [AppFailure]. The single place where
/// library-specific exception types are known.
abstract final class ErrorMapper {
  static AppFailure map(Object error, [StackTrace? stackTrace]) {
    return switch (error) {
      AppFailure() => error,
      DioException() => fromDio(error),
      TimeoutException() => NetworkFailure(
        reason: NetworkFailureReason.timeout,
        message: 'Operation timed out',
        cause: error,
      ),
      PlatformException() => StorageFailure(
        'Platform error: ${error.code}',
        error,
      ),
      FormatException() => UnknownFailure(
        'Malformed data: ${error.message}',
        error,
      ),
      _ => UnknownFailure(error.runtimeType.toString(), error),
    };
  }

  static AppFailure fromDio(DioException error) {
    // An interceptor may already have produced an AppFailure.
    final inner = error.error;
    if (inner is AppFailure) return inner;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkFailure(
          reason: NetworkFailureReason.timeout,
          message: 'Request timed out',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'Connection error', cause: error);
      case DioExceptionType.cancel:
        return CancelledFailure('Request cancelled', error);
      case DioExceptionType.badCertificate:
        return ServerFailure(message: 'Bad certificate', cause: error);
      case DioExceptionType.badResponse:
        return fromStatus(
          error.response?.statusCode,
          error.response?.data,
          cause: error,
        );
      case DioExceptionType.unknown:
        return UnknownFailure('Network request failed', error);
    }
  }

  /// Maps an HTTP status code (and optional JSON body) to a failure.
  ///
  /// Body convention understood by default:
  /// `{"message": "...", "errors": {"field": ["msg", ...]}}`.
  /// Adapt [_messageOf]/[_fieldErrorsOf] to your backend's format.
  static AppFailure fromStatus(int? status, Object? body, {Object? cause}) {
    final message = _messageOf(body);
    return switch (status) {
      400 || 422 => ValidationFailure(
        message: message ?? 'Validation failed',
        fieldErrors: _fieldErrorsOf(body),
        cause: cause,
      ),
      401 => UnauthorizedFailure(message ?? 'Unauthorized', cause),
      403 => ForbiddenFailure(message ?? 'Forbidden', cause),
      404 => NotFoundFailure(message ?? 'Not found', cause),
      final int s when s >= 500 => ServerFailure(
        message: message ?? 'Server error',
        statusCode: s,
        cause: cause,
      ),
      _ => ServerFailure(
        message: message ?? 'Unexpected status $status',
        statusCode: status,
        cause: cause,
      ),
    };
  }

  static String? _messageOf(Object? body) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return null;
  }

  static Map<String, List<String>> _fieldErrorsOf(Object? body) {
    if (body is! Map || body['errors'] is! Map) return const {};
    final raw = body['errors'] as Map;
    return {
      for (final entry in raw.entries)
        entry.key.toString(): switch (entry.value) {
          final List<dynamic> list => list.map((e) => e.toString()).toList(),
          final Object other => [other.toString()],
          null => const <String>[],
        },
    };
  }
}
