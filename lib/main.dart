import 'app/bootstrap/bootstrap.dart';

/// Entry point. The environment is selected at build time:
///
/// ```
/// flutter run --dart-define-from-file=config/development.json
/// ```
///
/// See README "Environments".
Future<void> main() => bootstrap();
