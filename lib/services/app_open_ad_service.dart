import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics/analytics_service.dart';
import 'ad_units.dart';

/// Manages the App Open ad (`AdUnits.appOpen`):
/// - New users: shown once right after Ishta Devta selection on onboarding.
/// - Existing users: shown at most once every 24 hours on app open.
class AppOpenAdService {
  AppOpenAdService._();
  static final AppOpenAdService instance = AppOpenAdService._();

  static const _lastShownKey = 'app_open_ad_last_shown_ms';
  static const _cooldown = Duration(hours: 24);
  static const _maxCacheDuration = Duration(hours: 4);
  static const _loadWait = Duration(seconds: 5);

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _onboardingPending = false;
  Completer<void>? _loadCompleter;

  void setOnboardingPending(bool pending) {
    _onboardingPending = pending;
  }

  /// Whether an App Open ad is currently cached and ready to show immediately.
  bool canShowNow({required bool adsEnabled}) {
    return !kIsWeb && adsEnabled && !_isShowing && _isAdAvailable;
  }

  bool get _isAdAvailable {
    final ad = _ad;
    final loadedAt = _loadedAt;
    if (ad == null || loadedAt == null) return false;
    if (DateTime.now().difference(loadedAt) >= _maxCacheDuration) {
      ad.dispose();
      _ad = null;
      _loadedAt = null;
      return false;
    }
    return true;
  }

  /// Preloads an App Open ad if ads are enabled and none is currently cached.
  void preload({required bool adsEnabled}) {
    if (kIsWeb || !adsEnabled || _isLoading || _isShowing || _isAdAvailable) {
      return;
    }
    _isLoading = true;
    _loadCompleter = Completer<void>();

    try {
      AppOpenAd.load(
        adUnitId: AdUnits.appOpen,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            ad.onPaidEvent = AnalyticsService.onPaidEvent('app_open');
            _ad = ad;
            _loadedAt = DateTime.now();
            _isLoading = false;
            _completeLoad();
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd failed to load: ${error.message}');
            _ad = null;
            _loadedAt = null;
            _isLoading = false;
            _completeLoad();
          },
        ),
      );
    } catch (e) {
      debugPrint('AppOpenAd.load threw: $e');
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

  /// Shows the preloaded App Open ad after a new user completes Ishta Devta
  /// selection, and records the 24-hour timestamp so they aren't shown
  /// another App Open ad on the same day.
  ///
  /// Returns immediately if no ad is ready so onboarding is never stalled.
  Future<void> showForNewUser({required bool adsEnabled}) async {
    _onboardingPending = false;
    if (kIsWeb || !adsEnabled || _isShowing) return;
    if (!_isAdAvailable) {
      preload(adsEnabled: adsEnabled);
      return;
    }
    await _present(adsEnabled: adsEnabled);
  }

  /// Shows the App Open ad for an existing user if 24 hours have passed since
  /// the last App Open ad impression.
  Future<void> showForExistingUserIfEligible({
    required bool adsEnabled,
    bool waitForLoad = false,
  }) async {
    if (kIsWeb || !adsEnabled || _isShowing || _onboardingPending) return;
    if (await _hasShownWithin24Hours()) return;

    if (!_isAdAvailable) {
      preload(adsEnabled: adsEnabled);
      if (waitForLoad) {
        final pending = _loadCompleter;
        if (pending != null) {
          try {
            await pending.future.timeout(_loadWait);
          } on TimeoutException {
            return;
          }
        }
      }
    }

    if (!_isAdAvailable || _isShowing) return;
    if (await _hasShownWithin24Hours()) return;

    await _present(adsEnabled: adsEnabled);
  }

  Future<void> _present({required bool adsEnabled}) async {
    final ad = _ad;
    if (ad == null) return;

    _ad = null;
    _loadedAt = null;
    _isShowing = true;
    await _markShownNow();

    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        _isShowing = false;
        shown.dispose();
        preload(adsEnabled: adsEnabled);
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('AppOpenAd failed to show: ${error.message}');
        _isShowing = false;
        shown.dispose();
        preload(adsEnabled: adsEnabled);
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('AppOpenAd show threw: $e');
      _isShowing = false;
      ad.dispose();
      preload(adsEnabled: adsEnabled);
      if (!dismissed.isCompleted) dismissed.complete();
      return;
    }

    try {
      await dismissed.future.timeout(const Duration(minutes: 2));
    } on TimeoutException {
      _isShowing = false;
    }
  }
}
