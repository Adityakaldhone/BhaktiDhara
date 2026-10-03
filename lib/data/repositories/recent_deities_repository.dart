import 'package:shared_preferences/shared_preferences.dart';

/// Repository for caching the LRU recent order of deities opened from Sacred Collection.
class RecentDeitiesRepository {
  static const String prefKey = 'recent_bhakti_deities_order_v1';

  /// Synchronously or eagerly loads the cached list of deity keys on app startup.
  static Future<List<String>> getInitialRecentDeities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(prefKey) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Loads the persisted recent deity keys.
  Future<List<String>> loadRecentDeities() async {
    return getInitialRecentDeities();
  }

  /// Persists the list of recent deity keys to SharedPreferences.
  Future<void> saveRecentDeities(List<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefKey, keys);
    } catch (_) {}
  }
}
