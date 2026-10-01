import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  SubscriptionService._();
  static final instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isBillingAvailable = false;
  List<ProductDetails> _storeProducts = [];
  Completer<SubscriptionStatus>? _activePurchaseCompleter;

  /// Holds the last error message for UI diagnostics.
  String? lastErrorMessage;

  bool get isBillingAvailable => _isBillingAvailable;
  List<ProductDetails> get storeProducts => _storeProducts;

  /// Initializes Google Play Billing and starts listening to the purchase stream.
  Future<void> initialize() async {
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

    // 1. Ensure Google Play Billing is connected
    if (!_isBillingAvailable) {
      _isBillingAvailable = await _iap.isAvailable();
    }

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
          'Subscription "${plan.productId}" was not returned by Google Play. Available products in store: $available';
      debugPrint('[SubscriptionService] $reason');
      lastErrorMessage = reason;
      throw Exception(reason);
    }

    final storeProduct = matchingProducts.first;

    // 5. Construct Google Play purchase params with best offerToken (Free Trial prioritized)
    PurchaseParam purchaseParam;
    if (Platform.isAndroid && storeProduct is GooglePlayProductDetails) {
      String? selectedOfferToken;
      String? selectedOfferId;

      // Check all matching products & offer wrappers for a Free Trial (priceAmountMicros == 0)
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
    } else {
      purchaseParam = PurchaseParam(productDetails: storeProduct);
    }

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
      lastErrorMessage ??= e.toString();
      rethrow;
    }
  }

  /// Handles incoming purchase updates from Google Play stream.
  Future<void> _onPurchaseDetailsUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[SubscriptionService] Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('[SubscriptionService] Purchase error: ${purchaseDetails.error}');
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
        );

        final plan = _planFromProductId(purchaseDetails.productID);
        final durationDays = plan != null ? plan.durationMonths * 30 : 30;

        final finalStatus = verifiedStatus ??
            SubscriptionStatus(
              isActive: true,
              tier: plan?.tier ?? _tierFromProductId(purchaseDetails.productID),
              expiresAt: DateTime.now().add(Duration(days: durationDays)),
              isTrial: verifiedStatus?.isTrial ?? false,
              autoRenewing: true,
              purchaseToken: token,
            );

        await saveSubscriptionStatus(finalStatus);

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        if (_activePurchaseCompleter != null && !_activePurchaseCompleter!.isCompleted) {
          _activePurchaseCompleter!.complete(finalStatus);
        }
      }
    }
  }

  /// Restores previous purchases through Google Play Billing and backend check.
  Future<SubscriptionStatus> restorePurchases() async {
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

      // Auto-cleanup for previous fake auto-trials:
      // Only clear if the device has a mock/unverified trial without a real Google Play token.
      // Real Google Play purchases/trials have real tokens and are NEVER cleared.
      if (isTrial && (token == null || token.isEmpty || token.startsWith('dev_token_'))) {
        await _clearLocalState(prefs);
        return SubscriptionStatus.free;
      }

      // 2. Check if active trial has expired
      if (isTrial && trialStartMs != null) {
        final trialStart = DateTime.fromMillisecondsSinceEpoch(trialStartMs);
        if (DateTime.now().isAfter(trialStart.add(const Duration(days: 7)))) {
          // Trial ended! Revert to free tier
          await prefs.setBool(_subStatusKey, false);
          await prefs.setBool(_subTrialKey, false);
          await prefs.setBool('is_bhaktidhara_premium_member', false);
          return SubscriptionStatus(
            isActive: false,
            isTrial: false,
            trialStartedAt: trialStart,
            expiresAt: trialStart.add(const Duration(days: 7)),
          );
        }
      }

      // 3. Check if paid subscription has expired
      if (isActive && tierIndex != null && expiryMs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
        if (DateTime.now().isAfter(expiry)) {
          // Subscription expired — clear local state
          await _clearLocalState(prefs);
          return SubscriptionStatus.free;
        }
      }

      return SubscriptionStatus(
        isActive: isActive,
        tier: tierIndex != null ? SubscriptionTier.values[tierIndex] : null,
        expiresAt: expiryMs != null
            ? DateTime.fromMillisecondsSinceEpoch(expiryMs)
            : null,
        isTrial: isTrial,
        trialStartedAt: trialStartMs != null
            ? DateTime.fromMillisecondsSinceEpoch(trialStartMs)
            : null,
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
