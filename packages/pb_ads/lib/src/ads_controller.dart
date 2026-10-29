import 'package:flutter/foundation.dart';

import 'ads_config.dart';

sealed class InterstitialOutcome {
  const InterstitialOutcome();
}

final class InterstitialShown extends InterstitialOutcome {
  const InterstitialShown();
}

/// Ads are off, not consented, premium, or no ad is loaded yet.
final class InterstitialNotAvailable extends InterstitialOutcome {
  const InterstitialNotAvailable();
}

/// The [InterstitialPolicy] said "not yet". Continue without an ad.
final class InterstitialThrottled extends InterstitialOutcome {
  const InterstitialThrottled();
}

final class InterstitialFailed extends InterstitialOutcome {
  const InterstitialFailed(this.code);
  final int code;
}

sealed class RewardedOutcome {
  const RewardedOutcome();
}

/// Grant the reward. Only this outcome means the user earned it.
final class RewardEarned extends RewardedOutcome {
  const RewardEarned(this.amount, this.type);
  final num amount;
  final String type;
}

/// Closed before the reward. Do not grant it.
final class RewardDismissed extends RewardedOutcome {
  const RewardDismissed();
}

final class RewardNotAvailable extends RewardedOutcome {
  const RewardNotAvailable();
}

final class RewardFailed extends RewardedOutcome {
  const RewardFailed(this.code);
  final int code;
}

enum ConsentOutcome { completed, notRequired, failed }

/// Mobile ads behind a product-facing API. No SDK type leaves pb_ads.
///
/// Deciding *when* an ad is appropriate is the product's call; this only
/// enforces consent, premium and the [InterstitialPolicy].
abstract interface class AdsController {
  /// False until consent allows ads, and whenever the user is premium.
  ValueListenable<bool> get adsAvailable;

  /// True when the user must be offered a "Privacy options" entry (GDPR).
  ValueListenable<bool> get privacyOptionsRequired;

  /// Null on platforms without a banner unit.
  String? get bannerAdUnitId;

  /// Gathers consent (shows the form if required) and starts the SDK. Call
  /// once, after the first frame.
  Future<void> initialize();

  Future<ConsentOutcome> showPrivacyOptions();
  Future<InterstitialOutcome> showInterstitial();
  Future<RewardedOutcome> showRewarded();

  /// Counts toward [InterstitialPolicy.minQualifyingActions] (e.g. "level
  /// finished", "article read").
  void recordQualifyingAction();

  Future<void> dispose();
}

/// Throttles interstitials by time and by qualifying actions. Pure logic.
class InterstitialFrequencyGovernor {
  InterstitialFrequencyGovernor(this.policy, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _lastShown = _clock();
  }

  final InterstitialPolicy policy;
  final DateTime Function() _clock;
  late DateTime _lastShown;
  int _actions = 0;

  void recordAction() => _actions++;

  bool get canShow =>
      _actions >= policy.minQualifyingActions &&
      _clock().difference(_lastShown) >= policy.minInterval;

  void markShown() {
    _lastShown = _clock();
    _actions = 0;
  }
}

/// In-process [AdsController] for tests, the demo and builds without ads.
/// Banners render as a labelled placeholder.
class FakeAdsController implements AdsController {
  FakeAdsController({
    bool available = true,
    InterstitialPolicy policy = const InterstitialPolicy(
      minInterval: Duration.zero,
      minQualifyingActions: 0,
    ),
    DateTime Function()? clock,
  }) : _available = ValueNotifier(available),
       governor = InterstitialFrequencyGovernor(policy, clock: clock);

  final ValueNotifier<bool> _available;
  final _privacy = ValueNotifier(false);
  final InterstitialFrequencyGovernor governor;
  int interstitialsShown = 0;
  RewardedOutcome nextReward = const RewardEarned(10, 'coins');

  set available(bool value) => _available.value = value;

  @override
  ValueListenable<bool> get adsAvailable => _available;

  @override
  ValueListenable<bool> get privacyOptionsRequired => _privacy;

  @override
  String? get bannerAdUnitId => 'fake-banner';

  @override
  Future<void> initialize() async {}

  @override
  Future<ConsentOutcome> showPrivacyOptions() async =>
      ConsentOutcome.notRequired;

  @override
  Future<InterstitialOutcome> showInterstitial() async {
    if (!_available.value) return const InterstitialNotAvailable();
    if (!governor.canShow) return const InterstitialThrottled();
    governor.markShown();
    interstitialsShown++;
    return const InterstitialShown();
  }

  @override
  Future<RewardedOutcome> showRewarded() async =>
      _available.value ? nextReward : const RewardNotAvailable();

  @override
  void recordQualifyingAction() => governor.recordAction();

  @override
  Future<void> dispose() async {
    _available.dispose();
    _privacy.dispose();
  }
}
