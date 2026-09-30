/// Subscription plan definitions for BhaktiDhara Premium.
///
/// Google Play product IDs must match exactly what's configured in Play Console.
enum SubscriptionTier {
  /// Monthly plan: ₹51/month
  monthly,

  /// Quarterly plan: ₹129/3 months (₹43/mo)
  quarterly,

  /// Half-yearly plan: ₹229/6 months (₹38/mo)
  halfYearly,

  /// Annual plan: ₹399/year (₹33/mo) — BEST VALUE
  annual,
}

/// Immutable description of a subscription plan shown in the paywall UI.
class SubscriptionPlan {
  final SubscriptionTier tier;

  /// Google Play in-app product ID — must match Play Console exactly.
  final String productId;

  /// Actual price in INR.
  final int priceInr;

  /// "Fake MRP" shown with strikethrough to create perceived discount.
  final int mrpInr;

  /// Duration in months.
  final int durationMonths;

  /// Whether this is the "recommended" / highlighted plan.
  final bool isRecommended;

  const SubscriptionPlan({
    required this.tier,
    required this.productId,
    required this.priceInr,
    required this.mrpInr,
    required this.durationMonths,
    this.isRecommended = false,
  });

  /// Per-month cost (rounded down).
  int get perMonth => (priceInr / durationMonths).floor();

  /// Discount percentage against the "MRP".
  int get discountPercent => (((mrpInr - priceInr) / mrpInr) * 100).round();

  /// How much the user "saves" against the fake MRP.
  int get savingsInr => mrpInr - priceInr;

  /// Label keys for each tier in multiple languages.
  String labelEn() {
    switch (tier) {
      case SubscriptionTier.monthly:
        return 'Monthly';
      case SubscriptionTier.quarterly:
        return '3 Months';
      case SubscriptionTier.halfYearly:
        return '6 Months';
      case SubscriptionTier.annual:
        return 'Annual';
    }
  }

  String labelHi() {
    switch (tier) {
      case SubscriptionTier.monthly:
        return 'मासिक';
      case SubscriptionTier.quarterly:
        return '3 महीने';
      case SubscriptionTier.halfYearly:
        return '6 महीने';
      case SubscriptionTier.annual:
        return 'वार्षिक';
    }
  }

  String labelMr() {
    switch (tier) {
      case SubscriptionTier.monthly:
        return 'मासिक';
      case SubscriptionTier.quarterly:
        return '३ महिने';
      case SubscriptionTier.halfYearly:
        return '६ महिने';
      case SubscriptionTier.annual:
        return 'वार्षिक';
    }
  }

  String label(String langCode) {
    switch (langCode) {
      case 'hi':
        return labelHi();
      case 'en':
        return labelEn();
      case 'mr':
      default:
        return labelMr();
    }
  }
}

/// All available BhaktiDhara Premium plans, ordered for display.
/// Annual plan is listed first (recommended) for maximum conversions.
const kSubscriptionPlans = [
  SubscriptionPlan(
    tier: SubscriptionTier.annual,
    productId: 'bhaktidhara_annual_399',
    priceInr: 399,
    mrpInr: 1188, // 99 × 12
    durationMonths: 12,
    isRecommended: true,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.halfYearly,
    productId: 'bhaktidhara_halfyearly_229',
    priceInr: 229,
    mrpInr: 594, // 99 × 6
    durationMonths: 6,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.quarterly,
    productId: 'bhaktidhara_quarterly_129',
    priceInr: 129,
    mrpInr: 297, // 99 × 3
    durationMonths: 3,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.monthly,
    productId: 'bhaktidhara_monthly_51',
    priceInr: 51,
    mrpInr: 99,
    durationMonths: 1,
  ),
];

/// Current subscription state for a user.
class SubscriptionStatus {
  /// Whether the user currently has an active premium subscription.
  final bool isActive;

  /// Which tier (null if not subscribed).
  final SubscriptionTier? tier;

  /// When the current period expires (null if not subscribed).
  final DateTime? expiresAt;

  /// Whether the user is currently in a free trial.
  final bool isTrial;

  /// When the trial started (null if no trial).
  final DateTime? trialStartedAt;

  /// Whether auto-renewal is on.
  final bool autoRenewing;

  /// Google Play purchase token for receipt validation.
  final String? purchaseToken;

  const SubscriptionStatus({
    this.isActive = false,
    this.tier,
    this.expiresAt,
    this.isTrial = false,
    this.trialStartedAt,
    this.autoRenewing = false,
    this.purchaseToken,
  });

  /// Default state: no subscription.
  static const free = SubscriptionStatus();

  /// Days remaining in trial (0 if not in trial or trial expired).
  int get trialDaysRemaining {
    if (trialStartedAt == null) return 0;
    final trialEnd = trialStartedAt!.add(const Duration(days: 7));
    final diff = trialEnd.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return (diff.inHours / 24).ceil().clamp(1, 7);
  }

  /// Whether the user was in a trial that has now expired.
  bool get trialExpired {
    if (trialStartedAt == null) return false;
    return DateTime.now().isAfter(
      trialStartedAt!.add(const Duration(days: 7)),
    );
  }

  SubscriptionStatus copyWith({
    bool? isActive,
    SubscriptionTier? tier,
    DateTime? expiresAt,
    bool? isTrial,
    DateTime? trialStartedAt,
    bool? autoRenewing,
    String? purchaseToken,
  }) {
    return SubscriptionStatus(
      isActive: isActive ?? this.isActive,
      tier: tier ?? this.tier,
      expiresAt: expiresAt ?? this.expiresAt,
      isTrial: isTrial ?? this.isTrial,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      autoRenewing: autoRenewing ?? this.autoRenewing,
      purchaseToken: purchaseToken ?? this.purchaseToken,
    );
  }
}
