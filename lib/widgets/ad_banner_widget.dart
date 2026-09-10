import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Displays an Anchored Adaptive Banner ad at the bottom of a screen.
///
/// The widget handles its own [BannerAd] lifecycle: it loads the ad in
/// [initState] and disposes it in [dispose]. Drop it at the end of a
/// scrollable content list (inside a non-scrollable wrapper) to keep it
/// pinned at the bottom.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final adSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (adSize == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    await ad.load();
    if (mounted) {
      setState(() => _bannerAd = ad);
    } else {
      ad.dispose();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Reserve no space until the ad loads so layout doesn't jump.
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: AdWidget(
              key: ValueKey(_bannerAd.hashCode),
              ad: _bannerAd!,
            ),
          ),
        ),
      ),
    );
  }
}
