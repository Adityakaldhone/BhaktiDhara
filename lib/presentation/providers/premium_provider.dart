import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/backend_service.dart';

/// StateNotifier that manages and persists the user's Premium membership status.
class PremiumNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'is_bhaktidhara_premium_member';

  PremiumNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      // In test environments or if prefs fail, keep default false
    }
  }

  Future<void> setPremium(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  Future<void> unlockPremium() async {
    BackendService.trackEvent('vip_unlock');
    try {
      final prefs = await SharedPreferences.getInstance();
      // A real unlock must survive the admin later revoking a complimentary grant.
      await prefs.setBool('vip_granted_by_admin', false);
    } catch (_) {}
    await setPremium(true);
  }

  Future<void> resetPremium() => setPremium(false);

  Future<void> togglePremium() => setPremium(!state);
}

/// Provider exposing whether the user is a Premium Member.
final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});
