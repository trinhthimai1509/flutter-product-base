import 'package:dio/dio.dart';

import '../error/error_mapper.dart';

/// Thin wrapper over Dio used by remote data sources.
///
/// Every method throws [AppFailure] (never [DioException]); wrap calls with
/// `guard()` in repositories to obtain a `Result`.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<T>(
      path,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.post<T>(
      path,
      data: data,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<T> put<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.put<T>(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<T> patch<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.patch<T>(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<T> delete<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.delete<T>(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    ),
  );

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (error) {
      throw ErrorMapper.fromDio(error);
    }
  }
}
