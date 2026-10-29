import 'package:flutter_test/flutter_test.dart';
import 'package:pb_connectivity/pb_connectivity.dart';

void main() {
  test('FakeNetworkMonitor reports and emits distinct changes', () async {
    final monitor = FakeNetworkMonitor();
    addTearDown(monitor.dispose);
    final emitted = <bool>[];
    final sub = monitor.onStatusChange.listen(emitted.add);
    addTearDown(sub.cancel);

    expect(await monitor.isOnline(), isTrue);
    monitor
      ..online = false
      ..online = false
      ..online = true;
    await pumpEventQueue();

    expect(emitted, [false, true]);
  });
}
