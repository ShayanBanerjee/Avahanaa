import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  void _loadAd() {
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
