import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_controller.dart';

/// An anchored adaptive banner. Renders nothing at all while ads are
/// unavailable (no consent, premium, unsupported platform, load failure),
/// so it can be placed unconditionally.
class AppBannerAd extends StatelessWidget {
  const AppBannerAd({super.key, required this.controller});

  final AdsController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.adsAvailable,
      builder: (context, available, _) {
        final unit = controller.bannerAdUnitId;
        if (!available || unit == null) return const SizedBox.shrink();
        if (controller is FakeAdsController) return const _FakeBanner();
        return _GoogleBanner(adUnitId: unit);
      },
    );
  }
}

class _FakeBanner extends StatelessWidget {
  const _FakeBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 50,
      alignment: Alignment.center,
      color: scheme.surfaceContainerHighest,
      child: Text(
        'Test banner',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _GoogleBanner extends StatefulWidget {
  const _GoogleBanner({required this.adUnitId});

  final String adUnitId;

  @override
  State<_GoogleBanner> createState() => _GoogleBannerState();
}

class _GoogleBannerState extends State<_GoogleBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _requestedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _requestedWidth) {
      _requestedWidth = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    await _ad?.dispose();
    _loaded = false;
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    setState(() => _ad = ad);
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
