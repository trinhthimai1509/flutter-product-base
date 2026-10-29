import 'package:flutter/foundation.dart';

/// One ad unit, per platform. Null means "no such unit on this platform".
class AdUnitIds {
  const AdUnitIds({this.android, this.ios});

  final String? android;
  final String? ios;

  String? get current {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }
}

/// Limits how often interstitials may interrupt the user.
class InterstitialPolicy {
  const InterstitialPolicy({
    this.minInterval = const Duration(minutes: 3),
    this.minQualifyingActions = 3,
  });

  /// Minimum time between two interstitials (and after app start).
  final Duration minInterval;

  /// Actions the user must complete (see
  /// `AdsController.recordQualifyingAction`) between two interstitials.
  final int minQualifyingActions;
}

/// Google's public test ids. Safe to click; never earn money.
abstract final class TestAdUnits {
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const banner = AdUnitIds(
    android: 'ca-app-pub-3940256099942544/9214589741',
    ios: 'ca-app-pub-3940256099942544/2435281174',
  );
  static const interstitial = AdUnitIds(
    android: 'ca-app-pub-3940256099942544/1033173712',
    ios: 'ca-app-pub-3940256099942544/4411468910',
  );
  static const rewarded = AdUnitIds(
    android: 'ca-app-pub-3940256099942544/5224354917',
    ios: 'ca-app-pub-3940256099942544/1712485313',
  );
}

class AdsConfig {
  const AdsConfig({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
    this.adsEnabled = true,
    this.interstitialPolicy = const InterstitialPolicy(),
    this.testDeviceIds = const [],
  });

  /// Google test units. Use for every non-production build.
  const AdsConfig.testAds({
    bool adsEnabled = true,
    InterstitialPolicy interstitialPolicy = const InterstitialPolicy(),
  }) : this(
         banner: TestAdUnits.banner,
         interstitial: TestAdUnits.interstitial,
         rewarded: TestAdUnits.rewarded,
         adsEnabled: adsEnabled,
         interstitialPolicy: interstitialPolicy,
       );

  final AdUnitIds banner;
  final AdUnitIds interstitial;
  final AdUnitIds rewarded;

  /// Master switch (e.g. from remote config or a build flag).
  final bool adsEnabled;
  final InterstitialPolicy interstitialPolicy;

  /// Devices that receive test ads with production units (from logcat /
  /// Xcode console "Use RequestConfiguration...setTestDeviceIds").
  final List<String> testDeviceIds;
}
