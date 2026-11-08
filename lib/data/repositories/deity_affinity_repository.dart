import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/logic/deity_affinity_ranker.dart';

/// Persists per-deity devotion history and the current Sacred Collection top band.
class DeityAffinityRepository {
  static const String prefKey = 'sacred_deity_affinity_v1';

  Future<({Map<String, DeityUsage> usage, List<String> top})> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKey);
      if (raw == null) return (usage: <String, DeityUsage>{}, top: <String>[]);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final usageJson = (json['usage'] as Map<String, dynamic>?) ?? const {};
      return (
        usage: {
          for (final e in usageJson.entries)
            e.key: DeityUsage.fromJson(e.value as Map<String, dynamic>),
        },
        top: ((json['top'] as List?) ?? const []).whereType<String>().toList(),
      );
    } catch (_) {
      return (usage: <String, DeityUsage>{}, top: <String>[]);
    }
  }

  Future<void> save(Map<String, DeityUsage> usage, List<String> top) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefKey,
        jsonEncode({
          'usage': {for (final e in usage.entries) e.key: e.value.toJson()},
          'top': top,
        }),
      );
    } catch (_) {}
  }
}
