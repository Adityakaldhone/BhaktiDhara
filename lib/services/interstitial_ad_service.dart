import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/analytics/analytics_service.dart';
import 'ad_units.dart';

/// One preloaded interstitial with a frequency cap, so full-screen ads never
/// show right after launch or back to back.
class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  static const _launchGrace = Duration(seconds: 60);
  static const _minGap = Duration(minutes: 3);

  final DateTime _startedAt = DateTime.now();
  DateTime? _lastShownAt;
  InterstitialAd? _ad;
  bool _loading = false;

  void preload() {
    if (kIsWeb || _loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdUnits.greetingInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.onPaidEvent = AnalyticsService.onPaidEvent('interstitial');
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: ${error.message}');
          _loading = false;
        },
      ),
    );
  }

  /// Shows the ad if one is ready and the frequency cap allows it.
  void maybeShow() {
    final ad = _ad;
    if (ad == null) {
      preload();
      return;
    }
    final now = DateTime.now();
    if (now.difference(_startedAt) < _launchGrace) return;
    if (_lastShownAt != null && now.difference(_lastShownAt!) < _minGap) return;

    _ad = null;
    _lastShownAt = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd failed to show: ${error.message}');
        ad.dispose();
        preload();
      },
    );
    ad.show();
  }
}
