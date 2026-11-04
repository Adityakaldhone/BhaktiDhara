import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart' show BillingResponse;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/analytics/analytics_service.dart';
import '../domain/entities/subscription_plan.dart';
import 'backend_service.dart';

/// Handles Google Play Billing subscription lifecycle.
///
/// This service is responsible for:
/// 1. Querying available products from Google Play
/// 2. Initiating purchases & free trials via Google Play Billing
/// 3. Listening for purchase updates via `purchaseStream`
/// 4. Verifying receipts with the backend server
/// 5. Persisting subscription state locally with fallback simulation for dev/testing
class SubscriptionService {
  static const _subStatusKey = 'bhaktidhara_sub_status';
  static const _subTierKey = 'bhaktidhara_sub_tier';
  static const _subExpiryKey = 'bhaktidhara_sub_expiry';
  static const _subTrialKey = 'bhaktidhara_sub_trial';
  static const _subTrialStartKey = 'bhaktidhara_sub_trial_start';
  static const _subAutoRenewKey = 'bhaktidhara_sub_auto_renew';
  static const _subTokenKey = 'bhaktidhara_sub_token';
  static const _loggedOrdersKey = 'bhaktidhara_analytics_logged_orders';

  /// Offer ID configured on every base plan in Play Console for the current
  /// festival sale. Play only returns it to accounts eligible for it.
  static const festiveOfferId = 'diwali-2026';

  SubscriptionService._();
  static final instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void>? _initFuture;
  bool _isBillingAvailable = false;
  List<ProductDetails> _storeProducts = [];
  Completer<SubscriptionStatus>? _activePurchaseCompleter;
  _CheckoutValue? _pendingCheckout;

  /// Holds the last error message for UI diagnostics.
  String? lastErrorMessage;

  bool get isBillingAvailable => _isBillingAvailable;
  List<ProductDetails> get storeProducts => _storeProducts;

  /// First-period price in rupees of the festive offer for [productId], or
  /// null when the offer is inactive or this account isn't eligible.
  int? festiveOfferPrice(String productId) {
    for (final p in _storeProducts) {
      if (p.id != productId || p is! GooglePlayProductDetails) continue;
      for (final offer in p.productDetails.subscriptionOfferDetails ?? const []) {
        if (offer.offerId != festiveOfferId || offer.pricingPhases.isEmpty) continue;
        return (offer.pricingPhases.first.priceAmountMicros / 1000000).round();
      }
    }
    return null;
  }

  /// Length in days of the free trial Play offers this account for
  /// [productId], or null when the account isn't eligible (e.g. it already
  /// used the trial) or products haven't loaded yet.
  int? freeTrialDays(String productId) {
    for (final p in _storeProducts) {
      if (p.id != productId || p is! GooglePlayProductDetails) continue;
      for (final offer in p.productDetails.subscriptionOfferDetails ?? const []) {
        for (final phase in offer.pricingPhases) {
          if (phase.priceAmountMicros == 0) return _periodDays(phase.billingPeriod);
        }
      }
    }
    return null;
  }

  /// Days in an ISO-8601 period such as "P7D" or "P1W".
  static int _periodDays(String period) {
    final m = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(period);
    if (m == null) return 7;
    int part(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
    final days = part(1) * 365 + part(2) * 30 + part(3) * 7 + part(4);
    return days > 0 ? days : 7;
  }

  static bool _isStoreToken(String? token) =>
      token != null && token.isNotEmpty && !token.startsWith('dev_token_');

  /// Initializes Google Play Billing and starts listening to the purchase stream.
  /// Safe to call repeatedly; concurrent callers share one connection attempt,
  /// and a failed attempt is retried on the next call.
  Future<void> initialize() {
    if (_subscription != null && _isBillingAvailable) return Future.value();
    return _initFuture ??= _initialize().whenComplete(() => _initFuture = null);
  }

  /// Building the native BillingClient makes a blocking Binder call on the
  /// Android main thread, so this must not run during app startup.
  Future<void> _initialize() async {
    if (kIsWeb) {
      debugPrint('[SubscriptionService] Store billing disabled on Web');
      return;
    }
    try {
      _isBillingAvailable = await _iap.isAvailable();
      if (!_isBillingAvailable) {
        debugPrint('[SubscriptionService] Store billing unavailable (fallback to simulation)');
        return;
      }

      // Listen to purchase stream
      _subscription ??= _iap.purchaseStream.listen(
        _onPurchaseDetailsUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (err) {
          debugPrint('[SubscriptionService] Purchase stream error: $err');
        },
      );

      // Query products from Google Play
      await refreshProducts();
    } catch (e) {
      debugPrint('[SubscriptionService] Init error: $e');
      _isBillingAvailable = false;
    }
  }

  /// Queries product details from store for all configured plans.
  Future<void> refreshProducts() async {
    if (kIsWeb) return;
    if (!_isBillingAvailable) {
      _isBillingAvailable = await _iap.isAvailable();
      if (!_isBillingAvailable) {
        debugPrint('[SubscriptionService] Google Play Billing is unavailable');
        return;
      }
    }
    try {
      final productIds = kSubscriptionPlans.map((p) => p.productId).toSet();
      final response = await _iap.queryProductDetails(productIds);
      if (response.error == null) {
        _storeProducts = response.productDetails;
        debugPrint(
          '[SubscriptionService] Loaded ${_storeProducts.length} store products: '
          '${_storeProducts.map((p) => p.id).toList()}',
        );
        for (final p in _storeProducts.whereType<GooglePlayProductDetails>()) {
          final offers = p.productDetails.subscriptionOfferDetails ?? const [];
          debugPrint(
            '[SubscriptionService] ${p.id} offers: '
            '${offers.map((o) => '${o.basePlanId}/${o.offerId ?? 'base'}').toList()}',
          );
        }
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint(
            '[SubscriptionService] WARNING: Google Play did NOT find product IDs: '
            '${response.notFoundIDs}. Check Play Console subscription setup.',
          );
        }
      } else {
        lastErrorMessage =
            'Google Play error: ${response.error!.message} (${response.error!.code})';
        debugPrint('[SubscriptionService] Query product error: ${response.error}');
      }
    } catch (e) {
      lastErrorMessage = 'Failed to query Google Play products: $e';
      debugPrint('[SubscriptionService] Refresh products error: $e');
    }
  }

  /// Buy a subscription plan.
  /// Launches official Google Play Billing sheet if available.
  Future<SubscriptionStatus> buyPlan(SubscriptionPlan plan) async {
    lastErrorMessage = null;
    BackendService.trackEvent(
      'subscription_purchase_start',
      item: plan.productId,
    );

    // In unit/widget tests, always simulate:
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return simulatePurchase(plan);
    }

    // 1. Ensure Google Play Billing is connected and purchase stream is attached
    await initialize();

    // 2. Fetch products if not yet loaded
    if (_isBillingAvailable && _storeProducts.isEmpty) {
      await refreshProducts();
    }

    // 3. Check if billing or products are missing
    if (!_isBillingAvailable || _storeProducts.isEmpty) {
      final reason = !_isBillingAvailable
          ? 'Google Play Billing is unavailable on this device. Ensure Google Play Store is installed and active.'
          : 'Google Play did not return product details for "${plan.productId}". Verify that this ID is Active in Play Console under Subscriptions and your tester account has access.';
      debugPrint('[SubscriptionService] $reason');
      lastErrorMessage = reason;

      // In debug mode on non-Android (simulator/web), allow fallback to simulation:
      if (kDebugMode && !Platform.isAndroid) {
        debugPrint(
          '[SubscriptionService] Falling back to simulation for ${plan.productId} (Debug/Non-Android)',
        );
        return simulatePurchase(plan);
      }

      throw Exception(reason);
    }

    // 4. Find all matching store products for this plan
    final matchingProducts =
        _storeProducts.where((p) => p.id == plan.productId).toList();

    if (matchingProducts.isEmpty) {
      final available = _storeProducts.map((p) => p.id).toList();
      final reason =
          'Subscription "${plan.productId}" is not yet propagated by Google Play. Available products in store: $available';
      debugPrint('[SubscriptionService] $reason');
      lastErrorMessage = reason;

      // In debug mode, allow simulated test purchase so developer testing is not blocked by Google Play CDN propagation delay
      if (kDebugMode) {
        debugPrint(
          '[SubscriptionService] Falling back to test simulation for ${plan.productId} (Debug Mode)',
        );
        return simulatePurchase(plan);
      }

      throw Exception(reason);
    }

    final storeProduct = matchingProducts.first;

    // 5. Construct Google Play purchase params with best offerToken (Free Trial prioritized)
    PurchaseParam purchaseParam;
    if (Platform.isAndroid && storeProduct is GooglePlayProductDetails) {
      String? selectedOfferToken;
      String? selectedOfferId;

      // The free trial wins; Play only returns it to accounts that haven't
      // used it, and those accounts get the festive offer instead.
      for (final p in matchingProducts) {
        if (p is GooglePlayProductDetails) {
          final offers = p.productDetails.subscriptionOfferDetails ?? [];
          for (final offer in offers) {
            final isFreeTrial = offer.pricingPhases
                .any((phase) => phase.priceAmountMicros == 0);
            if (isFreeTrial) {
              selectedOfferToken = offer.offerIdToken;
              selectedOfferId = offer.offerId;
              debugPrint(
                '[SubscriptionService] Selected Free Trial offer "$selectedOfferId" for ${plan.productId}',
              );
              break;
            }
          }
          if (selectedOfferToken != null) break;
        }
      }

      if (selectedOfferToken == null) {
        for (final p in matchingProducts) {
          if (p is GooglePlayProductDetails) {
            final offers = p.productDetails.subscriptionOfferDetails ?? [];
            for (final offer in offers) {
              if (offer.offerId == festiveOfferId) {
                selectedOfferToken = offer.offerIdToken;
                selectedOfferId = offer.offerId;
                debugPrint(
                  '[SubscriptionService] Selected festive offer "$selectedOfferId" for ${plan.productId}',
                );
                break;
              }
            }
            if (selectedOfferToken != null) break;
          }
        }
      }

      // Fallback: Check for any promotional offer (offerId is set)
      if (selectedOfferToken == null) {
        for (final p in matchingProducts) {
          if (p is GooglePlayProductDetails) {
            final offers = p.productDetails.subscriptionOfferDetails ?? [];
            for (final offer in offers) {
              if (offer.offerId != null && offer.offerId!.isNotEmpty) {
                selectedOfferToken = offer.offerIdToken;
                selectedOfferId = offer.offerId;
                debugPrint(
                  '[SubscriptionService] Selected promotional offer "$selectedOfferId" for ${plan.productId}',
                );
                break;
              }
            }
            if (selectedOfferToken != null) break;
          }
        }
      }

      // Prefer offer matching the plan's expected billing period (e.g. P3M, P6M, P1Y/P12M, P1M)
      if (selectedOfferToken == null) {
        final expectedPeriod = 'P${plan.durationMonths}M';
        for (final p in matchingProducts) {
          if (p is GooglePlayProductDetails) {
            final offers = p.productDetails.subscriptionOfferDetails ?? [];
            for (final offer in offers) {
              final matchesPeriod = offer.pricingPhases.any(
                (phase) =>
                    phase.billingPeriod == expectedPeriod ||
                    (plan.durationMonths == 12 && phase.billingPeriod == 'P1Y'),
              );
              if (matchesPeriod) {
                selectedOfferToken = offer.offerIdToken;
                selectedOfferId = offer.basePlanId;
                debugPrint(
                  '[SubscriptionService] Selected base plan "${offer.basePlanId}" matching duration ${plan.durationMonths}mo for ${plan.productId}',
                );
                break;
              }
            }
            if (selectedOfferToken != null) break;
          }
        }
      }

      // Final fallback: Use base plan offer token
      selectedOfferToken ??= storeProduct.offerToken ??
          storeProduct.productDetails.subscriptionOfferDetails?.firstOrNull
              ?.offerIdToken;

      debugPrint(
        '[SubscriptionService] Launching Google Play Billing for ${storeProduct.id} with offer: $selectedOfferId (token: $selectedOfferToken)',
      );
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: storeProduct,
        offerToken: selectedOfferToken,
      );
      _pendingCheckout = _checkoutValue(plan, matchingProducts, selectedOfferToken);
    } else {
      purchaseParam = PurchaseParam(productDetails: storeProduct);
      _pendingCheckout = _checkoutValue(plan, matchingProducts, null);
    }

    final checkout = _pendingCheckout!;
    AnalyticsService.logBeginCheckout(
      itemId: plan.productId,
      value: checkout.recurringPrice,
      currency: checkout.currency,
    );
    BackendService.syncAppInstanceId(trigger: 'begin_checkout', force: true);

    _activePurchaseCompleter = Completer<SubscriptionStatus>();

    try {
      final initiated = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!initiated) {
        _activePurchaseCompleter = null;
        lastErrorMessage =
            'Google Play Billing could not initiate purchase sheet for ${plan.productId}.';
        throw Exception(lastErrorMessage);
      }
      // Wait for purchase stream to process or timeout after 60 seconds
      return await _activePurchaseCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _activePurchaseCompleter = null;
          lastErrorMessage =
              'Purchase timed out waiting for Google Play response.';
          throw Exception(lastErrorMessage);
        },
      );
    } catch (e) {
      debugPrint('[SubscriptionService] buyPlan error: $e');
      _activePurchaseCompleter = null;
      if (e is IAPError && e.message == BillingResponse.itemAlreadyOwned.toString()) {
        final restored = await _restoreOwnedPurchase();
        if (restored.isActive) {
          lastErrorMessage = null;
          return restored;
        }
      }
      if (e is IAPError) lastErrorMessage ??= _describeBillingError(e);
      lastErrorMessage ??= e.toString();
      rethrow;
    }
  }

  /// Play says the user already owns the plan, so re-activate it locally
  /// through the restored purchase instead of showing an error.
  Future<SubscriptionStatus> _restoreOwnedPurchase() async {
    final completer = Completer<SubscriptionStatus>();
    _activePurchaseCompleter = completer;
    try {
      await _iap.restorePurchases();
      return await completer.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[SubscriptionService] Restore after itemAlreadyOwned failed: $e');
      return loadSubscriptionStatus();
    } finally {
      if (identical(_activePurchaseCompleter, completer)) _activePurchaseCompleter = null;
    }
  }

  /// Turns raw Play Billing errors into something a devotee can act on.
  static String _describeBillingError(IAPError error) {
    final message = error.message;
    if (message == BillingResponse.itemUnavailable.toString()) {
      return 'This plan is not available for your Google Play account right now. '
          'Make sure the Play Store is signed in with the account you installed the app from, '
          'update the Play Store, and try again.';
    }
    if (message == BillingResponse.itemAlreadyOwned.toString()) {
      return 'You already have this subscription. Tap "Restore Purchase" to activate it.';
    }
    if (message == BillingResponse.billingUnavailable.toString() ||
        message == BillingResponse.serviceUnavailable.toString() ||
        message == BillingResponse.serviceDisconnected.toString() ||
        message == BillingResponse.networkError.toString()) {
      return 'Could not reach Google Play. Check your internet connection and try again.';
    }
    if (message == BillingResponse.developerError.toString()) {
      return 'Google Play could not start this purchase. Please try again later.';
    }
    return 'Purchase could not be completed. Please try again.';
  }

  /// Handles incoming purchase updates from Google Play stream.
  Future<void> _onPurchaseDetailsUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[SubscriptionService] Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        final error = purchaseDetails.error;
        debugPrint('[SubscriptionService] Purchase error: $error');
        BackendService.trackEvent(
          'subscription_purchase_error',
          item: purchaseDetails.productID,
          props: {
            'code': error?.code ?? '',
            'message': error?.message ?? '',
            'details': '${error?.details ?? ''}',
          },
        );
        if (error?.message == BillingResponse.itemUnavailable.toString()) {
          // Offer tokens fetched at launch can go stale; re-query so the
          // next attempt uses what Play currently offers this account.
          _storeProducts = [];
          unawaited(refreshProducts());
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        if (_activePurchaseCompleter != null && !_activePurchaseCompleter!.isCompleted) {
          _activePurchaseCompleter!.completeError(purchaseDetails.error ?? 'Unknown error');
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('[SubscriptionService] Purchase canceled');
        if (_activePurchaseCompleter != null && !_activePurchaseCompleter!.isCompleted) {
          final current = await loadSubscriptionStatus();
          _activePurchaseCompleter!.complete(current);
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify with backend
        final token = purchaseDetails.verificationData.serverVerificationData;
        final verifiedStatus = await verifyReceipt(
          purchaseToken: token,
          productId: purchaseDetails.productID,
          orderId: purchaseDetails.purchaseID,
        );

        final plan = _planFromProductId(purchaseDetails.productID);
        final checkout = _pendingCheckout;
        final startedTrial = purchaseDetails.status == PurchaseStatus.purchased &&
            checkout?.productId == purchaseDetails.productID &&
            checkout!.chargedNow == 0;
        final trialDays = freeTrialDays(purchaseDetails.productID) ?? 7;
        final durationDays = startedTrial
            ? trialDays
            : (plan != null ? plan.durationMonths * 30 : 30);

        var finalStatus = verifiedStatus ??
            SubscriptionStatus(
              isActive: true,
              tier: plan?.tier ?? _tierFromProductId(purchaseDetails.productID),
              expiresAt: DateTime.now().add(Duration(days: durationDays)),
              isTrial: startedTrial,
              autoRenewing: true,
              purchaseToken: token,
            );
        if (startedTrial || finalStatus.isTrial) {
          finalStatus = finalStatus.copyWith(
            isTrial: true,
            trialStartedAt: finalStatus.trialStartedAt ?? DateTime.now(),
          );
        }

        await saveSubscriptionStatus(finalStatus);

        if (purchaseDetails.status == PurchaseStatus.purchased) {
          await _logPurchaseRevenue(purchaseDetails, verifiedStatus);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        if (_activePurchaseCompleter != null && !_activePurchaseCompleter!.isCompleted) {
          _activePurchaseCompleter!.complete(finalStatus);
        }
      }
    }
  }

  /// Resolves what the user is charged today for the chosen offer and what
  /// the plan renews at. A free-trial offer has a first pricing phase of 0.
  _CheckoutValue _checkoutValue(
    SubscriptionPlan plan,
    List<ProductDetails> products,
    String? offerToken,
  ) {
    if (offerToken != null) {
      for (final p in products) {
        if (p is! GooglePlayProductDetails) continue;
        for (final offer in p.productDetails.subscriptionOfferDetails ?? const []) {
          if (offer.offerIdToken != offerToken || offer.pricingPhases.isEmpty) continue;
          final recurring = offer.pricingPhases.last;
          return _CheckoutValue(
            productId: plan.productId,
            chargedNow: offer.pricingPhases.first.priceAmountMicros / 1000000.0,
            recurringPrice: recurring.priceAmountMicros / 1000000.0,
            currency: recurring.priceCurrencyCode,
          );
        }
      }
    }
    final p = products.first;
    return _CheckoutValue(
      productId: plan.productId,
      chargedNow: p.rawPrice,
      recurringPrice: p.rawPrice,
      currency: p.currencyCode,
    );
  }

  /// Sends the purchase (or trial start) to Firebase exactly once per order.
  /// Restored purchases never reach here, so re-installs don't inflate revenue.
  Future<void> _logPurchaseRevenue(
    PurchaseDetails details,
    SubscriptionStatus? verified,
  ) async {
    try {
      final checkout = _pendingCheckout?.productId == details.productID
          ? _pendingCheckout
          : _fallbackCheckout(details.productID, verified);
      _pendingCheckout = null;
      if (checkout == null) return;

      final orderId = details.purchaseID;
      final prefs = await SharedPreferences.getInstance();
      final logged = prefs.getStringList(_loggedOrdersKey) ?? const <String>[];
      if (orderId != null && logged.contains(orderId)) return;

      if (checkout.chargedNow == 0 || (verified?.isTrial ?? false)) {
        AnalyticsService.logTrialStart(
          itemId: checkout.productId,
          recurringPrice: checkout.recurringPrice,
          currency: checkout.currency,
        );
      } else {
        AnalyticsService.logPurchase(
          itemId: checkout.productId,
          value: checkout.chargedNow,
          currency: checkout.currency,
          transactionId: orderId,
        );
      }

      if (orderId != null) {
        final recent = logged.length >= 50 ? logged.sublist(logged.length - 49) : logged;
        await prefs.setStringList(_loggedOrdersKey, [...recent, orderId]);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Revenue logging failed: $e');
    }
  }

  /// Used when a purchase arrives without an in-app checkout (e.g. app was
  /// killed mid-purchase). Falls back to the catalogue INR price.
  _CheckoutValue? _fallbackCheckout(String productId, SubscriptionStatus? verified) {
    final plan = _planFromProductId(productId);
    if (plan == null) return null;
    final price = plan.priceInr.toDouble();
    return _CheckoutValue(
      productId: productId,
      chargedNow: (verified?.isTrial ?? false) ? 0 : price,
      recurringPrice: price,
      currency: 'INR',
    );
  }

  /// Restores previous purchases through Google Play Billing and backend check.
  Future<SubscriptionStatus> restorePurchases() async {
    await initialize();
    if (_isBillingAvailable) {
      try {
        await _iap.restorePurchases();
      } catch (e) {
        debugPrint('[SubscriptionService] Restore purchases error: $e');
      }
    }
    // Also check with backend
    final backendStatus = await checkStatusWithBackend();
    if (backendStatus != null && backendStatus.isActive) {
      await saveSubscriptionStatus(backendStatus);
      return backendStatus;
    }
    return loadSubscriptionStatus();
  }

  /// Reconciles local state with the subscriptions Google Play says this
  /// account owns right now: picks up trial conversions and renewals, and
  /// revokes plans that were cancelled, refunded or lapsed. Returns null when
  /// Play couldn't be asked or nothing changed, so callers keep what they have.
  Future<SubscriptionStatus?> syncWithStore() async {
    if (kIsWeb) return null;
    await initialize();
    if (!Platform.isAndroid || !_isBillingAvailable) return null;
    try {
      final response = await _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();
      if (response.error != null) return null;

      final owned = response.pastPurchases
          .where((p) =>
              p.status == PurchaseStatus.purchased &&
              _planFromProductId(p.productID) != null)
          .toList();
      final local = await loadSubscriptionStatus();

      if (owned.isEmpty) {
        if (!local.isActive || !_isStoreToken(local.purchaseToken)) return null;
        await _clearLocalState(await SharedPreferences.getInstance());
        return SubscriptionStatus.free;
      }

      final purchase = owned.first;
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      final plan = _planFromProductId(purchase.productID)!;
      final token = purchase.verificationData.serverVerificationData;
      final now = DateTime.now();
      final localExpiry = local.expiresAt;
      final samePurchase = local.purchaseToken == token;
      final status = SubscriptionStatus(
        isActive: true,
        tier: plan.tier,
        expiresAt: localExpiry != null && localExpiry.isAfter(now)
            ? localExpiry
            : now.add(Duration(days: plan.durationMonths * 30)),
        isTrial: samePurchase && local.isTrial,
        trialStartedAt: samePurchase ? local.trialStartedAt : null,
        autoRenewing: purchase.billingClientPurchase.isAutoRenewing,
        purchaseToken: token,
      );
      await saveSubscriptionStatus(status);
      return status;
    } catch (e) {
      debugPrint('[SubscriptionService] Store sync failed: $e');
      return null;
    }
  }

  /// Opens the native Google Play or Apple App Store subscription management page.
  /// Complies with Google Play Billing Policies and the FTC "Click to Cancel" rule,
  /// guaranteeing users can inspect, pause, change, or cancel recurring subscriptions in 1 tap.
  Future<void> openManageSubscription({String? sku}) async {
    const String package = 'com.kaldhone.bhaktidhara';
    final Uri url;

    if (!kIsWeb && Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      if (sku != null && sku.isNotEmpty) {
        url = Uri.parse(
          'https://play.google.com/store/account/subscriptions?sku=$sku&package=$package',
        );
      } else {
        url = Uri.parse(
          'https://play.google.com/store/account/subscriptions?package=$package',
        );
      }
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Error launching direct store url: $e');
    }

    // Fallback to general subscriptions page
    try {
      final fallbackUrl = Uri.parse(
        'https://play.google.com/store/account/subscriptions',
      );
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Fallback store URL error: $e');
    }
  }

  /// Load persisted subscription state from SharedPreferences.
  Future<SubscriptionStatus> loadSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_subStatusKey) ?? false;
      final tierIndex = prefs.getInt(_subTierKey);
      final expiryMs = prefs.getInt(_subExpiryKey);
      final isTrial = prefs.getBool(_subTrialKey) ?? false;
      final trialStartMs = prefs.getInt(_subTrialStartKey);
      final autoRenew = prefs.getBool(_subAutoRenewKey) ?? false;
      final token = prefs.getString(_subTokenKey);

      // 1. [TEMPORARILY COMMENTED OUT FOR TESTING IN-APP PURCHASE FLOW]:
      // First-time install: Automatically grant 7-Day Free Trial
      /*
      if (trialStartMs == null && !prefs.containsKey(_subStatusKey)) {
        final now = DateTime.now();
        final expiry = now.add(const Duration(days: 7));
        await prefs.setBool(_subStatusKey, true);
        await prefs.setBool(_subTrialKey, true);
        await prefs.setInt(_subTrialStartKey, now.millisecondsSinceEpoch);
        await prefs.setInt(_subExpiryKey, expiry.millisecondsSinceEpoch);
        await prefs.setBool('is_bhaktidhara_premium_member', true);
        return SubscriptionStatus(
          isActive: true,
          isTrial: true,
          trialStartedAt: now,
          expiresAt: expiry,
        );
      }
      */

      final storeBacked = _isStoreToken(token);

      // Trials that never went through Google Play were local simulations.
      if (isTrial && !storeBacked) {
        await _clearLocalState(prefs);
        return SubscriptionStatus.free;
      }

      // Play turns a trial into a paid plan and renews paid plans by itself,
      // so an auto-renewing store plan only ends when syncWithStore says so.
      if (isActive && expiryMs != null && !(storeBacked && autoRenew)) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
        if (DateTime.now().isAfter(expiry)) {
          await _clearLocalState(prefs);
          return SubscriptionStatus.free;
        }
      }

      final trialStart = trialStartMs != null
          ? DateTime.fromMillisecondsSinceEpoch(trialStartMs)
          : null;
      final stillInTrial = isTrial &&
          trialStart != null &&
          DateTime.now().isBefore(trialStart.add(const Duration(days: 7)));

      return SubscriptionStatus(
        isActive: isActive,
        tier: tierIndex != null ? SubscriptionTier.values[tierIndex] : null,
        expiresAt: expiryMs != null
            ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
            : null,
        isTrial: stillInTrial,
        trialStartedAt: trialStart,
        autoRenewing: autoRenew,
        purchaseToken: token,
      );
    } catch (_) {
      return SubscriptionStatus.free;
    }
  }

  /// Persist subscription state locally.
  Future<void> saveSubscriptionStatus(SubscriptionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subStatusKey, status.isActive);
      if (status.tier != null) {
        await prefs.setInt(_subTierKey, status.tier!.index);
      }
      if (status.expiresAt != null) {
        await prefs.setInt(
          _subExpiryKey,
          status.expiresAt!.millisecondsSinceEpoch,
        );
      }
      await prefs.setBool(_subTrialKey, status.isTrial);
      if (status.trialStartedAt != null) {
        await prefs.setInt(
          _subTrialStartKey,
          status.trialStartedAt!.millisecondsSinceEpoch,
        );
      }
      await prefs.setBool(_subAutoRenewKey, status.autoRenewing);
      if (status.purchaseToken != null) {
        await prefs.setString(_subTokenKey, status.purchaseToken!);
      }

      // Also sync with the existing premium provider key
      await prefs.setBool('is_bhaktidhara_premium_member', status.isActive);
    } catch (_) {}
  }

  /// Clear all local subscription state.
  Future<void> _clearLocalState(SharedPreferences prefs) async {
    await prefs.setBool(_subStatusKey, false);
    await prefs.remove(_subTierKey);
    await prefs.remove(_subExpiryKey);
    await prefs.setBool(_subTrialKey, false);
    await prefs.remove(_subTrialStartKey);
    await prefs.setBool(_subAutoRenewKey, false);
    await prefs.remove(_subTokenKey);
    await prefs.setBool('is_bhaktidhara_premium_member', false);
  }

  /// Verify a purchase receipt with the backend server.
  Future<SubscriptionStatus?> verifyReceipt({
    required String purchaseToken,
    required String productId,
    String? orderId,
  }) async {
    try {
      final deviceId = await BackendService.getAnonymousDeviceId();
      final url = Uri.parse(
        '${BackendService.backendUrl}/api/v1/subscription/verify',
      );
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'purchaseToken': purchaseToken,
              'productId': productId,
              'platform': _platformName,
              'orderId': orderId ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['verified'] == true) {
          final tier = _tierFromProductId(productId);
          return SubscriptionStatus(
            isActive: true,
            tier: tier,
            expiresAt: data['expiresAt'] != null
                ? DateTime.parse(data['expiresAt'] as String)
                : null,
            isTrial: data['isTrial'] == true,
            trialStartedAt: data['trialStartedAt'] != null
                ? DateTime.parse(data['trialStartedAt'] as String)
                : null,
            autoRenewing: data['autoRenewing'] == true,
            purchaseToken: purchaseToken,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check subscription status with the backend (used on app launch).
  Future<SubscriptionStatus?> checkStatusWithBackend() async {
    try {
      final deviceId = await BackendService.getAnonymousDeviceId();
      final url = Uri.parse(
        '${BackendService.backendUrl}/api/v1/subscription/status?deviceId=$deviceId',
      );
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['isActive'] == true) {
          return SubscriptionStatus(
            isActive: true,
            tier: data['tier'] != null
                ? _tierFromProductId(data['tier'] as String)
                : null,
            expiresAt: data['expiresAt'] != null
                ? DateTime.parse(data['expiresAt'] as String)
                : null,
            isTrial: data['isTrial'] == true,
            autoRenewing: data['autoRenewing'] == true,
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  SubscriptionTier? _tierFromProductId(String productId) {
    for (final plan in kSubscriptionPlans) {
      if (plan.productId == productId) return plan.tier;
    }
    return null;
  }

  SubscriptionPlan? _planFromProductId(String productId) {
    for (final plan in kSubscriptionPlans) {
      if (plan.productId == productId) return plan;
    }
    return null;
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEV/TEST SIMULATION — Seamless fallback when Google Play is not available
  // ═══════════════════════════════════════════════════════════════════════════

  /// Simulate a purchase for development/testing or when Play Services is unavailable.
  Future<SubscriptionStatus> simulatePurchase(SubscriptionPlan plan) async {
    BackendService.trackEvent(
      'subscription_purchase',
      item: plan.productId,
    );

    final now = DateTime.now();
    final status = SubscriptionStatus(
      isActive: true,
      tier: plan.tier,
      expiresAt: now.add(Duration(days: plan.durationMonths * 30)),
      isTrial: false,
      trialStartedAt: now,
      autoRenewing: true,
      purchaseToken: 'dev_token_${now.millisecondsSinceEpoch}',
    );

    await saveSubscriptionStatus(status);
    return status;
  }

  /// Simulate starting a fresh 7-day free trial.
  Future<SubscriptionStatus> simulateStartTrial() async {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 7));
    final status = SubscriptionStatus(
      isActive: true,
      isTrial: true,
      trialStartedAt: now,
      expiresAt: expiry,
      autoRenewing: false,
    );
    await saveSubscriptionStatus(status);
    return status;
  }

  /// Simulate free trial expiration (test trial-ended free state).
  Future<SubscriptionStatus> simulateExpireTrial() async {
    final now = DateTime.now();
    final eightDaysAgo = now.subtract(const Duration(days: 8));
    final status = SubscriptionStatus(
      isActive: false,
      isTrial: false,
      trialStartedAt: eightDaysAgo,
      expiresAt: eightDaysAgo.add(const Duration(days: 7)),
      autoRenewing: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, false);
    await prefs.setBool(_subTrialKey, false);
    await prefs.setInt(_subTrialStartKey, eightDaysAgo.millisecondsSinceEpoch);
    await prefs.setInt(_subExpiryKey, status.expiresAt!.millisecondsSinceEpoch);
    await prefs.setBool('is_bhaktidhara_premium_member', false);
    return status;
  }

  /// Simulate cancellation for development/testing.
  Future<void> simulateCancel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearLocalState(prefs);
    } catch (_) {}
    BackendService.trackEvent('subscription_cancel');
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

class _CheckoutValue {
  final String productId;
  final double chargedNow;
  final double recurringPrice;
  final String currency;

  const _CheckoutValue({
    required this.productId,
    required this.chargedNow,
    required this.recurringPrice,
    required this.currency,
  });
}
