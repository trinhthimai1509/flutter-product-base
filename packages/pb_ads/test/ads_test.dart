import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_ads/pb_ads.dart';

void main() {
  group('InterstitialFrequencyGovernor', () {
    late DateTime now;
    late InterstitialFrequencyGovernor governor;

    setUp(() {
      now = DateTime(2030);
      governor = InterstitialFrequencyGovernor(
        const InterstitialPolicy(
          minInterval: Duration(minutes: 3),
          minQualifyingActions: 2,
        ),
        clock: () => now,
      );
    });

    test('needs both enough actions and enough time', () {
      expect(governor.canShow, isFalse);

      governor
        ..recordAction()
        ..recordAction();
      expect(governor.canShow, isFalse, reason: 'too soon after start');

      now = now.add(const Duration(minutes: 3));
      expect(governor.canShow, isTrue);
    });

    test('markShown resets the counters', () {
      now = now.add(const Duration(minutes: 10));
      governor
        ..recordAction()
        ..recordAction()
        ..markShown();
      expect(governor.canShow, isFalse);

      now = now.add(const Duration(minutes: 3));
      expect(governor.canShow, isFalse, reason: 'no new actions');
    });
  });

  test('FakeAdsController honours availability and throttling', () async {
    var now = DateTime(2030);
    final ads = FakeAdsController(
      policy: const InterstitialPolicy(
        minInterval: Duration(minutes: 1),
        minQualifyingActions: 1,
      ),
      clock: () => now,
    );
    addTearDown(ads.dispose);

    expect(await ads.showInterstitial(), isA<InterstitialThrottled>());
    ads.recordQualifyingAction();
    now = now.add(const Duration(minutes: 1));
    expect(await ads.showInterstitial(), isA<InterstitialShown>());
    expect(ads.interstitialsShown, 1);

    ads.available = false;
    expect(await ads.showInterstitial(), isA<InterstitialNotAvailable>());
    expect(await ads.showRewarded(), isA<RewardNotAvailable>());
  });

  test('AdUnitIds resolve per platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(TestAdUnits.banner.current, TestAdUnits.banner.ios);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(TestAdUnits.banner.current, isNull);
  });

  testWidgets('AppBannerAd renders nothing while unavailable', (tester) async {
    final ads = FakeAdsController(available: false);
    addTearDown(ads.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppBannerAd(controller: ads)),
      ),
    );
    expect(find.text('Test banner'), findsNothing);

    ads.available = true;
    await tester.pump();
    expect(find.text('Test banner'), findsOneWidget);
  });
}
