import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Central singleton that manages the AdMob SDK lifecycle, interstitial
/// ad loading, and per-content-type view counters.
///
/// Usage:
///   await AdService.instance.initialize();            // call once in main()
///   AdService.instance.maybeShowInterstitial('joke'); // call in detail screens
///   AdService.instance.showInterstitialForDownload(); // call on download tap
class AdService {
  AdService._();
  static final instance = AdService._();

  // ── Ad unit IDs (test – replace with real IDs before release) ─────────────
  static const _bannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';
  static const _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  /// Expose banner unit ID so AdBannerWidget can read it.
  static String get bannerAdUnitId => _bannerAdUnitId;

  // ── Interstitial thresholds per content type ───────────────────────────────
  static const _thresholds = {
    'joke': 5,
    'story': 2,
    'recipe': 3,
    'video': 3,
    'quote': 3,
  };

  // ── Internal state ─────────────────────────────────────────────────────────
  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  /// Per-content-type view counters (reset to 0 after each ad show).
  final _viewCounts = <String, int>{};

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Call once at app startup (before runApp).
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadInterstitial();
  }

  /// Increments the view counter for [contentType] and shows the interstitial
  /// ad when the threshold for that type is reached.
  ///
  /// [contentType] should be one of: 'joke', 'story', 'recipe'.
  void maybeShowInterstitial(String contentType) {
    final threshold = _thresholds[contentType];
    if (threshold == null) return; // unsupported type — no-op

    _viewCounts[contentType] = (_viewCounts[contentType] ?? 0) + 1;
    if (_viewCounts[contentType]! >= threshold) {
      _viewCounts[contentType] = 0; // reset counter
      _showInterstitialIfReady();
    }
  }

  /// Show interstitial immediately — used for download button taps.
  /// If [onAdDismissed] is provided, it is invoked after the ad is closed (or immediately if ad is not ready).
  Future<void> showInterstitialForDownload({void Function()? onAdDismissed}) async {
    if (_interstitialAd != null) {
      final ad = _interstitialAd!;
      _interstitialAd = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitial();
          onAdDismissed?.call();
        },
      );
      await ad.show();
    } else {
      onAdDismissed?.call();
      _loadInterstitial();
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (_isAdLoading || _interstitialAd != null) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial(); // pre-load next ad immediately
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;
          // Retry after 30 s to avoid hammering the server on persistent failures
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  void _showInterstitialIfReady() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    }
    // If not loaded yet, the ad was not shown. The next threshold trigger will
    // attempt again once the background load completes.
  }
}
