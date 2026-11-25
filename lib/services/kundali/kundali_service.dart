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
  static const _userAgent = 'BhaktiDhara/1.2.16 (kundali-place-search)';
  static bool _tzReady = false;

  static void ensureTimezones() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  /// Converts the wall-clock birth time to UTC using the historical rules of
  /// the place's zone (e.g. India's +6:30 war time in 1942–45).
  static DateTime birthUtc(BirthProfile p) {
    ensureTimezones();
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

  /// Town / village / city search. Prefers India, merges Open-Meteo + OSM
  /// Nominatim so smaller birthplaces are easier to find.
  static Future<List<BirthPlace>> searchPlaces(String query, String langCode) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final openMeteo = await _searchOpenMeteo(q, langCode);
    if (openMeteo.length >= 8) return _dedupe(openMeteo);

    final nominatim = await _searchNominatim(q, langCode);
    return _dedupe([...openMeteo, ...nominatim]);
  }

  static Future<List<BirthPlace>> _searchOpenMeteo(String q, String langCode) async {
    Future<List<BirthPlace>> once({String? countryCode, String? language}) async {
      final params = <String, String>{
        'name': q,
        'count': '25',
        'language': language ?? langCode,
        'format': 'json',
      };
      if (countryCode != null) params['countryCode'] = countryCode;
      final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', params);
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) return const [];
        final results = (jsonDecode(res.body) as Map<String, dynamic>)['results'];
        if (results is! List) return const [];
        return [
          for (final r in results.cast<Map<String, dynamic>>())
            ?_openMeteoPlace(r),
        ];
      } catch (e) {
        debugPrint('Open-Meteo place search failed: $e');
        return const [];
      }
    }

    // India first (most users), then global + English spelling fallback.
    final india = await once(countryCode: 'IN');
    if (india.length >= 10) return india;

    final global = await once();
    final merged = _dedupe([...india, ...global]);
    if (merged.length >= 8 || langCode == 'en') return merged;

    final english = await once(countryCode: 'IN', language: 'en');
    return _dedupe([...merged, ...english]);
  }

  static BirthPlace? _openMeteoPlace(Map<String, dynamic> r) {
    final name = r['name'] as String?;
    final lat = r['latitude'];
    final lon = r['longitude'];
    if (name == null || lat is! num || lon is! num) return null;

    final countryCode = (r['country_code'] as String?)?.toUpperCase();
    final timezone = (r['timezone'] as String?) ??
        (countryCode == 'IN' ? 'Asia/Kolkata' : null);
    if (timezone == null) return null;

    final region = [
      r['admin2'],
      r['admin1'],
      r['country'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

    return BirthPlace(
      name: name,
      region: region,
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      timezone: timezone,
    );
  }

  static Future<List<BirthPlace>> _searchNominatim(String q, String langCode) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '20',
      'countrycodes': 'in',
      'accept-language': langCode == 'en' ? 'en' : '$langCode,en',
    });
    try {
      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      final results = jsonDecode(res.body);
      if (results is! List) return const [];
      return [
        for (final raw in results)
          if (raw is Map<String, dynamic>) ?_nominatimPlace(raw),
      ];
    } catch (e) {
      debugPrint('Nominatim place search failed: $e');
      return const [];
    }
  }

  static BirthPlace? _nominatimPlace(Map<String, dynamic> r) {
    final lat = double.tryParse('${r['lat']}');
    final lon = double.tryParse('${r['lon']}');
    if (lat == null || lon == null) return null;

    final address = r['address'];
    final addr = address is Map<String, dynamic> ? address : const <String, dynamic>{};
    String? pickName() {
      final direct = (r['name'] as String?)?.trim();
      if (direct != null && direct.isNotEmpty) return direct;
      for (final key in ['village', 'town', 'city', 'suburb', 'hamlet', 'county']) {
        final v = (addr[key] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      final display = (r['display_name'] as String?)?.split(',').first.trim();
      return (display != null && display.isNotEmpty) ? display : null;
    }

    final name = pickName();
    if (name == null) return null;

    final region = [
      addr['state_district'] ?? addr['county'],
      addr['state'],
      addr['country'],
    ].whereType<String>().where((s) => s.isNotEmpty && s != name).join(', ');

    return BirthPlace(
      name: name,
      region: region,
      latitude: lat,
      longitude: lon,
      timezone: 'Asia/Kolkata',
    );
  }

  static List<BirthPlace> _dedupe(List<BirthPlace> places) {
    final seen = <String>{};
    final out = <BirthPlace>[];
    for (final p in places) {
      final key =
          '${p.name.toLowerCase()}|${p.latitude.toStringAsFixed(2)}|${p.longitude.toStringAsFixed(2)}';
      if (seen.add(key)) out.add(p);
    }
    return out;
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
