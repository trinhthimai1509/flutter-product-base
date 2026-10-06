import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_project_base/core/auth/access_token_source.dart';
import 'package:flutter_project_base/core/error/app_failure.dart';
import 'package:flutter_project_base/core/network/api_client.dart';
import 'package:flutter_project_base/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns 401 unless the request carries `Bearer <validToken>`.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.validToken);

  String validToken;
  final List<String?> seenAuthHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'] as String?;
    seenAuthHeaders.add(auth);
    final ok = auth == 'Bearer $validToken';
    return ResponseBody.fromString(
      jsonEncode(ok ? {'ok': true} : {'message': 'nope'}),
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TokenSource implements AccessTokenSource {
  _TokenSource(this.token, {this.refreshTo});

  String? token;
  final String? refreshTo;
  int refreshCalls = 0;
  bool expired = false;

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<bool> refresh() async {
    refreshCalls++;
    if (refreshTo == null) return false;
    token = refreshTo;
    return true;
  }

  @override
  Future<void> onSessionExpired() async => expired = true;
}

(ApiClient, _FakeAdapter) _client(_TokenSource source, String validToken) {
  final adapter = _FakeAdapter(validToken);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  final retry = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(tokenSource: source, retryClient: retry),
  );
  return (ApiClient(dio), adapter);
}

void main() {
  test('injects bearer token', () async {
    final source = _TokenSource('good');
    final (client, adapter) = _client(source, 'good');
    final body = await client.get<Map<String, dynamic>>('/me');
    expect(body, {'ok': true});
    expect(adapter.seenAuthHeaders, ['Bearer good']);
  });

  test('refreshes once on 401 and replays the request', () async {
    final source = _TokenSource('stale', refreshTo: 'fresh');
    final (client, adapter) = _client(source, 'fresh');
    final body = await client.get<Map<String, dynamic>>('/me');
    expect(body, {'ok': true});
    expect(source.refreshCalls, 1);
    expect(adapter.seenAuthHeaders, ['Bearer stale', 'Bearer fresh']);
  });

  test('expires the session when refresh fails', () async {
    final source = _TokenSource('stale');
    final (client, _) = _client(source, 'fresh');
    await expectLater(
      client.get<Map<String, dynamic>>('/me'),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(source.expired, isTrue);
  });

  test('skipAuth requests are untouched', () async {
    final source = _TokenSource('good');
    final (client, adapter) = _client(source, 'good');
    await expectLater(
      client.get<Map<String, dynamic>>(
        '/public',
        options: Options(extra: {AuthInterceptor.skipAuth: true}),
      ),
      throwsA(isA<UnauthorizedFailure>()),
    );
    expect(adapter.seenAuthHeaders, [null]);
    expect(source.refreshCalls, 0);
  });
}
