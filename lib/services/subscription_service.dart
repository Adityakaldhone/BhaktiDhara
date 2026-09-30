import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/subscription_plan.dart';
import 'backend_service.dart';

/// Handles Google Play Billing subscription lifecycle.
///
/// This service is responsible for:
/// 1. Querying available products from Google Play
/// 2. Initiating purchases & free trials
/// 3. Listening for purchase updates
/// 4. Verifying receipts with the backend
/// 5. Persisting subscription state locally
///
/// NOTE: `in_app_purchase` package must be added to pubspec.yaml for production.
/// Until then, this service provides a simulated flow for development/testing.
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

      // 1. First-time install: Automatically grant 7-Day Free Trial
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
  ///
  /// Returns the verified [SubscriptionStatus] from the server, or null
  /// if verification failed.
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

  static String get _platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEV/TEST MODE — Simulated purchase for development until in_app_purchase
  // is wired up with actual Google Play products.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Simulate a purchase for development/testing.
  /// In production, this will be replaced with actual Google Play Billing flow.
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
}
