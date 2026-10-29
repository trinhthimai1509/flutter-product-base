import 'package:flutter_test/flutter_test.dart';
import 'package:pb_telemetry_firebase/pb_telemetry_firebase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to no-op telemetry when Firebase is unavailable', () async {
    // No native Firebase in unit tests: initialization fails, like a fresh
    // clone without `flutterfire configure`.
    final telemetry = await FirebaseTelemetry.initialize();
    expect(telemetry.isNoOp, isTrue);
  });
}
