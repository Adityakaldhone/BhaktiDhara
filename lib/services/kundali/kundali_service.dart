import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/birth_profile.dart';
import 'vedic_astro_engine.dart';

class KundaliService {
  static const _prefsKey = 'kundali_profiles_v1';
  static bool _tzReady = false;

  static void _ensureTimezones() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  /// Converts the wall-clock birth time to UTC using the historical rules of
  /// the place's zone (e.g. India's +6:30 war time in 1942–45).
  static DateTime birthUtc(BirthProfile p) {
    _ensureTimezones();
    final b = p.birthLocal;
    try {
      final location = tz.getLocation(p.place.timezone);
      return tz.TZDateTime(location, b.year, b.month, b.day, b.hour, b.minute)
          .toUtc();
    } catch (_) {
      // Unknown zone: fall back to local mean time from longitude.
      final offset = Duration(minutes: (p.place.longitude * 4).round());
      return DateTime.utc(b.year, b.month, b.day, b.hour, b.minute).subtract(offset);
    }
  }

  /// UTC offset in effect at the birth moment, for display.
  static Duration birthOffset(BirthProfile p) {
    final b = p.birthLocal;
    final asUtc = DateTime.utc(b.year, b.month, b.day, b.hour, b.minute);
    return asUtc.difference(birthUtc(p));
  }

  static KundaliData calculate(BirthProfile p) => const VedicAstroEngine().calculate(
        birthUtc: birthUtc(p),
        latitude: p.place.latitude,
        longitude: p.place.longitude,
      );

  /// Town / city search via the free Open-Meteo geocoding API.
  static Future<List<BirthPlace>> searchPlaces(String query, String langCode) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': q,
      'count': '15',
      'language': langCode,
      'format': 'json',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final results = (jsonDecode(res.body) as Map<String, dynamic>)['results'];
      if (results is! List) return const [];
      return [
        for (final r in results.cast<Map<String, dynamic>>())
          if (r['timezone'] != null)
            BirthPlace(
              name: r['name'] as String,
              region: [r['admin1'], r['country']]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(', '),
              latitude: (r['latitude'] as num).toDouble(),
              longitude: (r['longitude'] as num).toDouble(),
              timezone: r['timezone'] as String,
            ),
      ];
    } catch (e) {
      debugPrint('Kundali place search failed: $e');
      return const [];
    }
  }

  static Future<List<BirthProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(BirthProfile.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveProfiles(List<BirthProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }
}
