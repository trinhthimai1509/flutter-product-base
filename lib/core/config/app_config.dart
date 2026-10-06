/// Runtime environments supported by the base.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String? value) {
    return AppEnvironment.values.firstWhere(
      (e) => e.name == value?.trim().toLowerCase(),
      orElse: () => AppEnvironment.development,
    );
  }
}

/// Immutable application configuration.
///
/// Values come from `--dart-define` / `--dart-define-from-file` at build time
/// (see `config/*.json` and README). Never put secrets here: anything compiled
/// into the client can be extracted from the binary.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableNetworkLogs = false,
    this.logNetworkBodies = false,
    this.useFakeBackend = false,
  });

  /// Reads configuration from compile-time environment declarations.
  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    final environment = AppEnvironment.parse(env);
    final isProd = environment == AppEnvironment.production;
    return AppConfig(
      environment: environment,
      appName: const String.fromEnvironment(
        'APP_NAME',
        defaultValue: 'Flutter Base',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.example.com',
      ),
      connectTimeout: Duration(
        milliseconds: const int.fromEnvironment(
          'CONNECT_TIMEOUT_MS',
          defaultValue: 15000,
        ),
      ),
      receiveTimeout: Duration(
        milliseconds: const int.fromEnvironment(
          'RECEIVE_TIMEOUT_MS',
          defaultValue: 30000,
        ),
      ),
      // Network logs are never enabled in production, whatever the flag says.
      enableNetworkLogs:
          !isProd &&
          const bool.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: true),
      logNetworkBodies:
          !isProd &&
          const bool.fromEnvironment('LOG_NETWORK_BODIES', defaultValue: false),
      useFakeBackend: const bool.fromEnvironment(
        'USE_FAKE_BACKEND',
        defaultValue: true,
      ),
    );
  }

  final AppEnvironment environment;
  final String appName;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableNetworkLogs;
  final bool logNetworkBodies;

  /// When true, features use in-process fake data sources instead of HTTP.
  /// Lets the base run without a backend; turn off once an API exists.
  final bool useFakeBackend;

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
}
