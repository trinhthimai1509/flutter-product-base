import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pb_common/pb_common.dart';

import 'ads_config.dart';
import 'ads_controller.dart';

/// [AdsController] over Google Mobile Ads + User Messaging Platform.
///
/// Requires the AdMob app id in AndroidManifest.xml / Info.plist (see
/// docs/MODULE_CATALOG.md#pb_ads); without it the native SDK crashes at
/// launch.
class GoogleAdsController implements AdsController {
  GoogleAdsController({
    required this.config,
    PremiumState premiumState = PremiumState.alwaysFree,
    this._logger = const NoOpPbLogger(),
    DateTime Function()? clock,
  }) : _premium = premiumState,
       _governor = InterstitialFrequencyGovernor(
         config.interstitialPolicy,
         clock: clock,
       );

  final AdsConfig config;
  final PremiumState _premium;
  final PbLogger _logger;
  final InterstitialFrequencyGovernor _governor;

  final _available = ValueNotifier(false);
  final _privacyRequired = ValueNotifier(false);
  StreamSubscription<PremiumStatus>? _premiumSub;
  bool _canRequestAds = false;
  bool _sdkStarted = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  ValueListenable<bool> get adsAvailable => _available;

  @override
  ValueListenable<bool> get privacyOptionsRequired => _privacyRequired;

  @override
  String? get bannerAdUnitId => config.banner.current;

  void _refresh() {
    final wasAvailable = _available.value;
    _available.value =
        _supported &&
        config.adsEnabled &&
        _canRequestAds &&
        _sdkStarted &&
        _premium.current != PremiumStatus.premium;
    if (_available.value && !wasAvailable) {
      _loadInterstitial();
      _loadRewarded();
    } else if (!_available.value) {
      _disposeLoadedAds();
    }
  }

  @override
  Future<void> initialize() async {
    if (!_supported || !config.adsEnabled) return;
    _premiumSub ??= _premium.changes.listen((_) => _refresh());
    try {
      await _gatherConsent();
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (_canRequestAds && !_sdkStarted) {
        await MobileAds.instance.initialize();
        if (config.testDeviceIds.isNotEmpty) {
          await MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(testDeviceIds: config.testDeviceIds),
          );
        }
        _sdkStarted = true;
      }
    } on Object catch (error) {
      _logger.warning('Ads initialization failed', tag: 'ads', error: error);
    }
    _refresh();
  }

  Future<void> _gatherConsent() async {
    final updated = Completer<FormError?>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(null),
      updated.complete,
    );
    final updateError = await updated.future;
    if (updateError != null) {
      // Offline or misconfigured: a previous consent may still allow ads.
      _logger.warning(
        'Consent update failed: ${updateError.message}',
        tag: 'ads',
      );
      return;
    }
    final shown = Completer<FormError?>();
    await ConsentForm.loadAndShowConsentFormIfRequired(shown.complete);
    final formError = await shown.future;
    if (formError != null) {
      _logger.warning('Consent form error: ${formError.message}', tag: 'ads');
    }
    _privacyRequired.value =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<ConsentOutcome> showPrivacyOptions() async {
    if (!_supported || !_privacyRequired.value) {
      return ConsentOutcome.notRequired;
    }
    final dismissed = Completer<FormError?>();
    await ConsentForm.showPrivacyOptionsForm(dismissed.complete);
    final error = await dismissed.future;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    _refresh();
    return error == null ? ConsentOutcome.completed : ConsentOutcome.failed;
  }

  void _loadInterstitial() {
    final unit = config.interstitial.current;
    if (unit == null || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _logger.info(
          'Interstitial failed to load: ${error.code}',
          tag: 'ads',
        ),
      ),
    );
  }

  void _loadRewarded() {
    final unit = config.rewarded.current;
    if (unit == null || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) =>
            _logger.info('Rewarded failed to load: ${error.code}', tag: 'ads'),
      ),
    );
  }

  @override
  Future<InterstitialOutcome> showInterstitial() async {
    if (!_available.value) return const InterstitialNotAvailable();
    if (!_governor.canShow) return const InterstitialThrottled();
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return const InterstitialNotAvailable();
    }
    _interstitial = null;
    final result = Completer<InterstitialOutcome>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(const InterstitialShown());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(InterstitialFailed(error.code));
        }
      },
    );
    await ad.show();
    final outcome = await result.future;
    if (outcome is InterstitialShown) _governor.markShown();
    _loadInterstitial();
    return outcome;
  }

  @override
  Future<RewardedOutcome> showRewarded() async {
    if (!_available.value) return const RewardNotAvailable();
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return const RewardNotAvailable();
    }
    _rewarded = null;
    RewardItem? reward;
    final result = Completer<RewardedOutcome>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) {
          result.complete(
            reward == null
                ? const RewardDismissed()
                : RewardEarned(reward!.amount, reward!.type),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!result.isCompleted) result.complete(RewardFailed(error.code));
      },
    );
    await ad.show(onUserEarnedReward: (_, item) => reward = item);
    final outcome = await result.future;
    _loadRewarded();
    return outcome;
  }

  @override
  void recordQualifyingAction() => _governor.recordAction();

  void _disposeLoadedAds() {
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
  }

  @override
  Future<void> dispose() async {
    await _premiumSub?.cancel();
    _disposeLoadedAds();
    _available.dispose();
    _privacyRequired.dispose();
  }
}
