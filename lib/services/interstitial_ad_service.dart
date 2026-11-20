import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/analytics/analytics_service.dart';
import 'ad_units.dart';

/// One preloaded interstitial with a light frequency cap.
///
/// Use [maybeShowAfterAction] for best-effort post-action ads.
/// Use [showBeforeAction] when the reward (share sheet / gallery save) must
/// run after the ad closes — or immediately if no ad is available.
class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  static const _minGap = Duration(minutes: 2);
  static const _loadWait = Duration(seconds: 4);
  static const _resumeSettle = Duration(milliseconds: 450);

  DateTime? _lastShownAt;
  InterstitialAd? _ad;
  bool _loading = false;
  Completer<void>? _loadCompleter;

  void preload() {
    if (kIsWeb || _loading || _ad != null) return;
    _loading = true;
    _loadCompleter = Completer<void>();
    InterstitialAd.load(
      adUnitId: AdUnits.greetingInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.onPaidEvent = AnalyticsService.onPaidEvent('interstitial');
          _ad = ad;
          _loading = false;
          _completeLoad();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: ${error.message}');
          _loading = false;
          _completeLoad();
        },
      ),
    );
  }

  void _completeLoad() {
    final c = _loadCompleter;
    if (c != null && !c.isCompleted) c.complete();
    _loadCompleter = null;
  }

  Future<void> _waitUntilReady() async {
    if (_ad != null) return;
    if (!_loading) preload();
    final pending = _loadCompleter;
    if (pending == null) return;
    try {
      await pending.future.timeout(_loadWait);
    } on TimeoutException {
      // Proceed without an ad rather than blocking the user action.
    }
  }

  Future<void> _waitForResume() async {
    final binding = WidgetsBinding.instance;
    if (binding.lifecycleState == null ||
        binding.lifecycleState == AppLifecycleState.resumed) {
      await Future<void>.delayed(_resumeSettle);
      return;
    }
    final done = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        if (!done.isCompleted) done.complete();
      },
    );
    try {
      await done.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Fall through and attempt show anyway.
    } finally {
      listener.dispose();
    }
    await Future<void>.delayed(_resumeSettle);
  }

  bool _gapAllowsShow() {
    final last = _lastShownAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minGap;
  }

  /// Best-effort show after share sheet / save. Never blocks the caller.
  Future<void> maybeShowAfterAction() async {
    if (kIsWeb) return;
    await _waitForResume();
    await _waitUntilReady();
    if (_ad == null || !_gapAllowsShow()) {
      if (_ad == null) preload();
      return;
    }
    await _present(requireDismissCallback: false);
  }

  /// Shows an interstitial (if ready and allowed), then completes after the
  /// ad is dismissed and the app has resumed — so share sheets / gallery
  /// writes aren't racing the lifecycle transition. If no ad can be shown,
  /// completes immediately so the caller can continue.
  Future<void> showBeforeAction() async {
    if (kIsWeb) return;
    await _waitUntilReady();
    if (_ad == null || !_gapAllowsShow()) {
      if (_ad == null) preload();
      return;
    }
    await _present(requireDismissCallback: true);
    await _waitForResume();
  }

  Future<void> _present({required bool requireDismissCallback}) async {
    final ad = _ad;
    if (ad == null) return;

    _ad = null;
    _lastShownAt = DateTime.now();

    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        preload();
        if (!dismissed.isCompleted) dismissed.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('InterstitialAd failed to show: ${error.message}');
        shown.dispose();
        preload();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('InterstitialAd show threw: $e');
      ad.dispose();
      preload();
      if (!dismissed.isCompleted) dismissed.complete();
      return;
    }

    if (requireDismissCallback) {
      try {
        await dismissed.future.timeout(const Duration(minutes: 2));
      } on TimeoutException {
        // Safety valve so download is never stuck behind a hung ad.
      }
    }
  }
}
