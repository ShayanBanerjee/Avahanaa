import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_gate.dart';

class AdMobBanner extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const AdMobBanner({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  static const _liveAdUnitId = 'ca-app-pub-1536607795745971/3375803419';
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (_isSupportedPlatform) {
      _loadAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Loads the banner once the SDK is ready.
  ///
  /// `main()` kicks off `MobileAds.initialize()` without awaiting it, so the
  /// launch path is not held open by an ad SDK. That means this widget can be
  /// built before initialisation finishes, and a `BannerAd.load()` at that
  /// point fails. `initialize()` is idempotent and returns the same completed
  /// status once it has run, so awaiting it here is free in the common case
  /// and correct in the racy one.
  Future<void> _loadAd() async {
    await MobileAds.instance.initialize();
    if (!mounted) return;

    final adUnitId = kReleaseMode ? _liveAdUnitId : _testAdUnitId;

    final bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() => _isLoaded = false);
          }
        },
      ),
    );

    bannerAd.load();
    _bannerAd = bannerAd;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedPlatform || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Subscribers do not see this. Gated at paint rather than at load, so a
    // subscription that lapses mid-session restores the banner without a
    // restart, and one that activates removes it in the same frame the wallet
    // stream reports it.
    return ValueListenableBuilder<bool>(
      valueListenable: adsAllowed,
      builder: (context, allowed, child) =>
          allowed ? child! : const SizedBox.shrink(),
      child: _banner(),
    );
  }

  Widget _banner() {
    return Padding(
      padding: widget.padding,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  bool get _isSupportedPlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }
}
