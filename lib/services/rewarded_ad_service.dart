import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/analytics/analytics_service.dart';
import 'backend_service.dart';

/// Singleton service that manages a single preloaded [RewardedAd].
///
/// Call [RewardedAdService.instance.preload()] once at app startup to start
/// loading the first ad. Then call [show()] to display it when the user
/// taps "Watch Ad to Unlock".
///
/// After the ad is consumed (watched or failed), the next ad is automatically
/// preloaded.
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  // ── Production Ad Unit ID ────────────────────────────────────────────────
  static const _adUnitId = 'ca-app-pub-2701330811649318/2339619579';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Whether a rewarded ad is ready to be shown.
  bool get isLoaded => _rewardedAd != null;

  /// Preload a rewarded ad. Safe to call multiple times (no-ops if already
  /// loading or loaded). Silently fails on web or in test environments.
  void preload() {
    if (kIsWeb || _isLoading || _rewardedAd != null) return;

    _isLoading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.onPaidEvent = AnalyticsService.onPaidEvent('rewarded');
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: ${error.message}');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// Show the rewarded ad. Calls [onRewarded] when the user earns the reward
  /// (i.e. watched the full video). Calls [onAdNotReady] if no ad is available
  /// yet — you can show a snackbar or fallback to the paywall in that case.
  ///
  /// After the ad is dismissed (regardless of reward), a fresh ad is preloaded.
  void show({
    required void Function() onRewarded,
    void Function()? onAdNotReady,
  }) {
    if (_rewardedAd == null) {
      onAdNotReady?.call();
      preload(); // try loading again for next time
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preload(); // reload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        preload();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        BackendService.trackEvent('rewarded_ad_earned', item: '${reward.type}:${reward.amount}');
        AnalyticsService.logFunnelEvent(FunnelEvent.rewardedAdEarned);
        onRewarded();
      },
    );
  }

  /// Dispose the current ad (call on app teardown if needed).
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
