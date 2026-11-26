import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics/analytics_service.dart';
import 'ad_units.dart';

/// Manages the Rewarded Interstitial ad for Horoscope & Panchang screens,
/// shown at most once every 24 hours.
class RewardedInterstitialAdService {
  RewardedInterstitialAdService._();
  static final RewardedInterstitialAdService instance =
      RewardedInterstitialAdService._();

  static const _lastShownKey = 'rewarded_interstitial_last_shown_ms';
  static const _cooldown = Duration(hours: 24);
  static const _loadWait = Duration(seconds: 4);

  RewardedInterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;
  Completer<void>? _loadCompleter;

  void preload({required bool adsEnabled}) {
    if (kIsWeb || !adsEnabled || _isLoading || _isShowing || _ad != null) {
      return;
    }
    _isLoading = true;
    _loadCompleter = Completer<void>();

    try {
      RewardedInterstitialAd.load(
        adUnitId: AdUnits.horoscopePanchangRewardedInterstitial,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.onPaidEvent =
                AnalyticsService.onPaidEvent('rewarded_interstitial');
            _ad = ad;
            _isLoading = false;
            _completeLoad();
          },
          onAdFailedToLoad: (error) {
            debugPrint(
                'RewardedInterstitialAd failed to load: ${error.message}');
            _ad = null;
            _isLoading = false;
            _completeLoad();
          },
        ),
      );
    } catch (e) {
      debugPrint('RewardedInterstitialAd.load threw: $e');
      _isLoading = false;
      _completeLoad();
    }
  }

  void _completeLoad() {
    final c = _loadCompleter;
    if (c != null && !c.isCompleted) c.complete();
    _loadCompleter = null;
  }

  Future<bool> _hasShownWithin24Hours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_lastShownKey);
      if (lastMs == null) return false;
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastMs);
      return DateTime.now().difference(lastShown) < _cooldown;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markShownNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Best effort; ignore storage failures.
    }
  }

  /// Shows the Rewarded Interstitial ad if 24 hours have passed since the last
  /// impression and ads are enabled.
  Future<void> showIfEligible({required bool adsEnabled}) async {
    if (kIsWeb || !adsEnabled || _isShowing) return;
    if (await _hasShownWithin24Hours()) return;

    if (_ad == null) {
      preload(adsEnabled: adsEnabled);
      final pending = _loadCompleter;
      if (pending != null) {
        try {
          await pending.future.timeout(_loadWait);
        } on TimeoutException {
          return;
        }
      }
    }

    final ad = _ad;
    if (ad == null || _isShowing) return;
    if (await _hasShownWithin24Hours()) return;

    _ad = null;
    _isShowing = true;
    await _markShownNow();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        _isShowing = false;
        shown.dispose();
        preload(adsEnabled: adsEnabled);
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('RewardedInterstitialAd failed to show: ${error.message}');
        _isShowing = false;
        shown.dispose();
        preload(adsEnabled: adsEnabled);
      },
    );

    try {
      await ad.show(onUserEarnedReward: (_, _) {});
    } catch (e) {
      debugPrint('RewardedInterstitialAd show threw: $e');
      _isShowing = false;
      ad.dispose();
      preload(adsEnabled: adsEnabled);
    }
  }
}
