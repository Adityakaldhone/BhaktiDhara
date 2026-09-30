import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../services/subscription_service.dart';
import 'premium_provider.dart';

/// Manages the full subscription lifecycle state.
///
/// This provider loads persisted subscription state on creation and exposes
/// methods to purchase, cancel, and restore subscriptions.
class SubscriptionNotifier extends StateNotifier<SubscriptionStatus> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(SubscriptionStatus.free) {
    _loadState();
  }

  Future<void> _loadState() async {
    final status = await SubscriptionService.instance.loadSubscriptionStatus();
    state = status;
    // Keep premium provider in sync
    _ref.read(isPremiumProvider.notifier).setPremium(status.isActive);
  }

  /// Refresh subscription status from backend (call on app launch).
  Future<void> refreshFromBackend() async {
    final backendStatus =
        await SubscriptionService.instance.checkStatusWithBackend();
    if (backendStatus != null) {
      state = backendStatus;
      await SubscriptionService.instance.saveSubscriptionStatus(backendStatus);
      _ref.read(isPremiumProvider.notifier).setPremium(backendStatus.isActive);
    }
  }

  /// Purchase a subscription plan.
  ///
  /// In production, this will trigger Google Play Billing flow.
  /// Currently uses simulated purchase for development.
  Future<bool> purchasePlan(SubscriptionPlan plan) async {
    try {
      // TODO: Replace with actual Google Play Billing flow:
      // 1. Query product details from Google Play
      // 2. Launch billing flow
      // 3. Listen for purchase updates
      // 4. Verify receipt with backend
      // 5. Update local state
      //
      // For now, simulate the purchase:
      final status =
          await SubscriptionService.instance.simulatePurchase(plan);
      state = status;
      _ref.read(isPremiumProvider.notifier).setPremium(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start a 7-day free trial.
  Future<void> startFreeTrial() async {
    final status = await SubscriptionService.instance.simulateStartTrial();
    state = status;
    _ref.read(isPremiumProvider.notifier).setPremium(true);
  }

  /// Simulate trial expiration (for testing trial-ended free UI).
  Future<void> expireTrialForDev() async {
    final status = await SubscriptionService.instance.simulateExpireTrial();
    state = status;
    _ref.read(isPremiumProvider.notifier).setPremium(false);
  }

  /// Cancel the current subscription.
  Future<void> cancelSubscription() async {
    await SubscriptionService.instance.simulateCancel();
    state = SubscriptionStatus.free;
    _ref.read(isPremiumProvider.notifier).setPremium(false);
  }

  /// Restore a previous purchase (e.g., after reinstall).
  Future<bool> restorePurchase() async {
    final backendStatus =
        await SubscriptionService.instance.checkStatusWithBackend();
    if (backendStatus != null && backendStatus.isActive) {
      state = backendStatus;
      await SubscriptionService.instance.saveSubscriptionStatus(backendStatus);
      _ref.read(isPremiumProvider.notifier).setPremium(true);
      return true;
    }
    return false;
  }
}

/// Provider exposing the current subscription status.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus>((ref) {
  return SubscriptionNotifier(ref);
});

/// Provider for the currently selected plan index in the paywall UI.
final selectedPlanIndexProvider = StateProvider<int>((ref) => 0);
