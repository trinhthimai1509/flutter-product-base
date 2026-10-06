import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/di/core_providers.dart';
import '../../core/logging/app_logger.dart';
import '../../core/storage/key_value_store.dart';
import '../../features/auth/application/auth_token_source.dart';
import '../app.dart';

/// Initializes async dependencies, installs global error handlers and runs
/// the app. Keep this small: features initialize lazily via providers.
Future<void> bootstrap({
  AppConfig? config,
  List<Override> overrides = const [],
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = config ?? AppConfig.fromEnvironment();
  final logger = DeveloperLogger();

  FlutterError.onError = (details) {
    logger.error(
      details.exceptionAsString(),
      tag: 'flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error(
      'Uncaught error',
      tag: 'zone',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  final keyValueStore = await SharedPreferencesStore.create();
  final appInfo = await _loadAppInfo();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
        appInfoProvider.overrideWithValue(appInfo),
        appLoggerProvider.overrideWithValue(logger),
        keyValueStoreProvider.overrideWithValue(keyValueStore),
        accessTokenSourceProvider.overrideWith(AuthTokenSource.new),
        ...overrides,
      ],
      child: const App(),
    ),
  );
}

Future<AppInfo> _loadAppInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(version: info.version, buildNumber: info.buildNumber);
  } on Object {
    return const AppInfo(version: 'unknown', buildNumber: '0');
  }
}
