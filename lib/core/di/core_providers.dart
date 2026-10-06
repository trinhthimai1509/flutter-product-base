import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/access_token_source.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../network/dio_factory.dart';
import '../storage/key_value_store.dart';
import '../storage/secure_store.dart';

/// Core dependency graph. Riverpod providers are the DI container: override
/// any of them in `ProviderScope(overrides: ...)` (bootstrap or tests).

/// Must be overridden in bootstrap.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

/// App name/version from the platform. Overridden in bootstrap.
final appInfoProvider = Provider<AppInfo>(
  (ref) => const AppInfo(version: '0.0.0', buildNumber: '0'),
);

class AppInfo {
  const AppInfo({required this.version, required this.buildNumber});
  final String version;
  final String buildNumber;
}

final appLoggerProvider = Provider<AppLogger>((ref) => DeveloperLogger());

/// Must be overridden in bootstrap (needs async init).
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError('keyValueStoreProvider must be overridden'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStore(),
);

/// Overridden by the auth feature in bootstrap; core never imports features.
final accessTokenSourceProvider = Provider<AccessTokenSource>(
  (ref) => const NoAccessTokenSource(),
);

/// Dio without auth handling (auth endpoints, public APIs).
final publicDioProvider = Provider<Dio>((ref) {
  final dio = DioFactory.createPublic(
    ref.watch(appConfigProvider),
    ref.watch(appLoggerProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Dio with bearer token injection and refresh-on-401.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = DioFactory.createAuthenticated(
    ref.watch(appConfigProvider),
    ref.watch(appLoggerProvider),
    ref.watch(accessTokenSourceProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

final publicApiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(publicDioProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(authenticatedDioProvider)),
);
