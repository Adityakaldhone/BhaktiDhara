import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';

/// Funnel milestones forwarded to Firebase so Google Ads can optimise on them.
///
/// The `name` values are the conversion event names shown in Google Ads —
/// renaming one silently breaks any campaign bidding on it.
enum FunnelEvent {
  aartiOpen('aarti_open'),
  aartiCompleted('aarti_completed'),
  jaapGoalComplete('jaap_goal_complete'),
  paywallView('paywall_view'),
  rewardedAdEarned('rewarded_ad_earned'),
  trialStart('trial_start'),
  retainedD1('retained_d1'),
  retainedD7('retained_d7');

  const FunnelEvent(this.name);
  final String name;
}

/// Single entry point for revenue + funnel events sent to Firebase Analytics
/// (and from there to Google Ads for tCPA / tROAS bidding).
///
/// Every method is fire-and-forget and never throws: analytics must never
/// affect the devotee's experience.
class AnalyticsService {
  AnalyticsService._();

  /// AdMob `onPaidEvent` revenue is logged as `paid_ad_revenue`, never as
  /// `ad_impression`, because a Firebase-linked AdMob app logs `ad_impression`
  /// automatically. Import only one of the two into Google Ads as a value source.
  static const bool logPaidAdRevenue = true;
  static const paidAdRevenueEvent = 'paid_ad_revenue';

  static const _installDateKey = 'analytics_install_date_ms';
  static const _retentionLoggedKey = 'analytics_retention_logged';

  static Future<FirebaseAnalytics?>? _ready;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Starts Firebase Analytics without blocking the first frame. Call from
  /// `main()` so `first_open` / `session_start` attach to the launch session.
  static Future<void> init() => _analytics();

  static Future<FirebaseAnalytics?> _analytics() => _ready ??= _init();

  static Future<FirebaseAnalytics?> _init() async {
    if (!_supported) return null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      if (kDebugMode) debugPrint('[Analytics] Firebase Analytics ready');
      return FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('[Analytics] Firebase Analytics unavailable: $e');
      return null;
    }
  }

  static Future<void> _run(
    String event,
    Map<String, Object?> params,
    Future<void> Function(FirebaseAnalytics fa) action,
  ) async {
    if (kDebugMode) debugPrint('[Analytics] $event $params');
    try {
      final fa = await _analytics();
      if (fa != null) await action(fa);
    } catch (e) {
      debugPrint('[Analytics] $event dropped: $e');
    }
  }

  // ── Ad revenue ──────────────────────────────────────────────────────────

  /// Returns an AdMob `onPaidEvent` handler that logs the impression's revenue.
  /// Usage: `BannerAdListener(onPaidEvent: AnalyticsService.onPaidEvent('banner'))`.
  static OnPaidEventCallback onPaidEvent(String adFormat) {
    return (ad, valueMicros, precision, currencyCode) => logPaidAdRevenueEvent(
          ad: ad,
          adFormat: adFormat,
          valueMicros: valueMicros,
          precision: precision,
          currencyCode: currencyCode,
        );
  }

  /// Logs `paid_ad_revenue` with the exact `value` and `currency` AdMob pinged.
  /// The currency is the AdMob account's reporting currency (INR if unset).
  static Future<void> logPaidAdRevenueEvent({
    required Ad ad,
    required String adFormat,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
  }) {
    if (!logPaidAdRevenue || valueMicros <= 0) return Future.value();
    final adSource = ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName;
    final params = <String, Object>{
      'value': valueMicros / 1000000.0,
      'currency': currencyCode.isEmpty ? 'INR' : currencyCode,
      'ad_platform': 'AdMob',
      'ad_source': (adSource == null || adSource.isEmpty) ? 'AdMob Network' : adSource,
      'ad_format': adFormat,
      'ad_unit_name': ad.adUnitId,
      'precision': precision.name,
    };
    return _run(
      paidAdRevenueEvent,
      params,
      (fa) => fa.logEvent(name: paidAdRevenueEvent, parameters: params),
    );
  }

  // ── Purchases / subscriptions ───────────────────────────────────────────

  /// Logs the standard Firebase `purchase` event with the exact amount charged.
  /// [transactionId] should be the store order id so GA4 can de-duplicate.
  static Future<void> logPurchase({
    required String itemId,
    required double value,
    required String currency,
    String? transactionId,
    String? itemName,
  }) {
    return _run(
      'purchase',
      {'item_id': itemId, 'value': value, 'currency': currency, 'transaction_id': transactionId},
      (fa) => fa.logPurchase(
        value: value,
        currency: currency,
        transactionId: transactionId,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName ?? itemId,
            itemCategory: 'subscription',
            price: value,
            quantity: 1,
          ),
        ],
      ),
    );
  }

  /// Logs `begin_checkout` when the Play Billing sheet is about to open.
  static Future<void> logBeginCheckout({
    required String itemId,
    required double value,
    required String currency,
  }) {
    return _run(
      'begin_checkout',
      {'item_id': itemId, 'value': value, 'currency': currency},
      (fa) => fa.logBeginCheckout(
        value: value,
        currency: currency,
        items: [AnalyticsEventItem(itemId: itemId, price: value, quantity: 1)],
      ),
    );
  }

  /// A free trial charges nothing today, so it is logged without `value` —
  /// importing it as a revenue conversion would inflate ROAS.
  static Future<void> logTrialStart({
    required String itemId,
    required double recurringPrice,
    required String currency,
  }) {
    return logFunnelEvent(FunnelEvent.trialStart, parameters: {
      'item_id': itemId,
      'plan_price': recurringPrice,
      'plan_currency': currency,
    });
  }

  /// GA4 `app_instance_id` for this install, needed by the backend to send
  /// Measurement Protocol events (renewals, trial conversions) for this user.
  static Future<String?> appInstanceId() async {
    try {
      final fa = await _analytics();
      return await fa?.appInstanceId;
    } catch (_) {
      return null;
    }
  }

  // ── Funnel / retention ──────────────────────────────────────────────────

  static Future<void> logFunnelEvent(FunnelEvent event, {Map<String, Object>? parameters}) {
    return _run(
      event.name,
      parameters ?? const {},
      (fa) => fa.logEvent(name: event.name, parameters: parameters),
    );
  }

  /// Call once per app launch. Logs `retained_d1` / `retained_d7` the first
  /// time the user returns on day 1 / day 7+ after install.
  static Future<void> logAppLaunch() async {
    if (!_supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final installMs = prefs.getInt(_installDateKey);
      if (installMs == null) {
        await prefs.setInt(_installDateKey, now.millisecondsSinceEpoch);
        return;
      }
      final install = DateTime.fromMillisecondsSinceEpoch(installMs);
      final days = DateTime(now.year, now.month, now.day)
          .difference(DateTime(install.year, install.month, install.day))
          .inDays;
      final logged = prefs.getStringList(_retentionLoggedKey) ?? const [];

      FunnelEvent? milestone;
      if (days >= 7 && !logged.contains(FunnelEvent.retainedD7.name)) {
        milestone = FunnelEvent.retainedD7;
      } else if (days == 1 && !logged.contains(FunnelEvent.retainedD1.name)) {
        milestone = FunnelEvent.retainedD1;
      }
      if (milestone == null) return;

      await prefs.setStringList(_retentionLoggedKey, [...logged, milestone.name]);
      await logFunnelEvent(milestone, parameters: {'days_since_install': days});
    } catch (_) {}
  }
}
