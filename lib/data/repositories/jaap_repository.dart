import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/jaap_progress.dart';

/// Persists [JaapProgress] as a single JSON blob in SharedPreferences.
class JaapRepository {
  static const String _prefKey = 'jaap_progress_v1';

  Future<JaapProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null) return const JaapProgress();
      return JaapProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const JaapProgress();
    }
  }

  Future<void> save(JaapProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(progress.toJson()));
    } catch (_) {}
  }
}
