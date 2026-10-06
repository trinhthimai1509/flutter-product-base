import 'package:dio/dio.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/auth_credential.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';

/// Talks to the auth backend. Implementations throw [AppFailure].
abstract interface class AuthRemoteDataSource {
  Future<AuthSession> signIn(AuthCredential credential);
  Future<AuthSession> refresh(String refreshToken);
  Future<void> signOut(AuthSession session);
}

/// REST implementation. Endpoint paths and JSON shape are a common
/// convention; adapt [_parseSession] and paths to your backend.
///
/// Expected response:
/// `{"accessToken": "...", "refreshToken": "...", "expiresIn": 3600,
///   "user": {"id": "...", "email": "...", "displayName": "..."}}`
class HttpAuthRemoteDataSource implements AuthRemoteDataSource {
  HttpAuthRemoteDataSource(this._client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ApiClient _client;
  final DateTime Function() _clock;

  @override
  Future<AuthSession> signIn(AuthCredential credential) async {
    final (path, body) = switch (credential) {
      GuestCredential() => ('/auth/guest', <String, dynamic>{}),
      EmailPasswordCredential(:final email, :final password) => (
        '/auth/login',
        {'email': email, 'password': password},
      ),
      OAuthCredential(:final provider, :final token) => (
        '/auth/oauth/$provider',
        {'token': token},
      ),
    };
    final json = await _client.post<Map<String, dynamic>>(path, data: body);
    return _parseSession(json, isAnonymous: credential is GuestCredential);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _parseSession(json);
  }

  @override
  Future<void> signOut(AuthSession session) async {
    await _client.post<void>(
      '/auth/logout',
      data: {'refreshToken': session.refreshToken},
      options: Options(
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        extra: {AuthInterceptor.skipAuth: true},
      ),
    );
  }

  AuthSession _parseSession(Map<String, dynamic> json, {bool? isAnonymous}) {
    try {
      final userJson = json['user'] as Map<String, dynamic>;
      final expiresIn = json['expiresIn'] as int?;
      return AuthSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: expiresIn == null
            ? null
            : _clock().add(Duration(seconds: expiresIn)),
        user: AuthUser(
          id: userJson['id'].toString(),
          email: userJson['email'] as String?,
          displayName: userJson['displayName'] as String?,
          avatarUrl: userJson['avatarUrl'] as String?,
          isAnonymous: isAnonymous ?? userJson['isAnonymous'] as bool? ?? false,
        ),
      );
    } on Object catch (error) {
      throw UnknownFailure('Malformed auth response', error);
    }
  }
}
