import 'package:flutter_test/flutter_test.dart';
import 'package:pb_common/pb_common.dart';

void main() {
  test('alwaysFree is free and never changes', () async {
    expect(PremiumState.alwaysFree.current, PremiumStatus.free);
    expect(await PremiumState.alwaysFree.changes.isEmpty, isTrue);
  });

  test('FakePremiumState emits only real changes', () async {
    final state = FakePremiumState();
    addTearDown(state.dispose);
    final emitted = <PremiumStatus>[];
    final sub = state.changes.listen(emitted.add);
    addTearDown(sub.cancel);

    state
      ..current = PremiumStatus.free
      ..current = PremiumStatus.premium
      ..current = PremiumStatus.premium;
    await pumpEventQueue();

    expect(state.current, PremiumStatus.premium);
    expect(emitted, [PremiumStatus.premium]);
  });
}
