import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/horoscope.dart';
import '../domain/entities/panchang.dart';

/// Client service that connects the Flutter app to your Hetzner Python FastAPI backend.
/// Automatically handles anonymous device telemetry, daily caching, and seamless offline fallbacks.
class BackendService {
  /// Configure this via `--dart-define=BACKEND_URL=https://api.yourdomain.com`
  /// or set it directly in code.
  static String backendUrl = const String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://46.225.142.210',
  );

  /// Keep in sync with `version:` in pubspec.yaml.
  static const appVersion = '1.0.4';

  static const _anonIdKey = 'anon_device_id';
  static const _premiumKey = 'is_bhaktidhara_premium_member';
  static const _adminGrantedVipKey = 'vip_granted_by_admin';

  /// Generates or retrieves a persistent, randomized 128-bit UUID for the device.
  /// Collects ZERO personal information (no phone, no email, no name, no Google account).
  static Future<String> getAnonymousDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString(_anonIdKey);
      if (deviceId == null || deviceId.isEmpty) {
        final random = Random.secure();
        final bytes = List<int>.generate(16, (i) => random.nextInt(256));
        bytes[6] = (bytes[6] & 0x0f) | 0x40; // UUID v4
        bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
        deviceId = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        await prefs.setString(_anonIdKey, deviceId);
      }
      return deviceId;
    } catch (_) {
      return 'anon-device-fallback';
    }
  }

  static const _devoteeNameKey = 'devotee_user_name';
  static const _cachedCityKey = 'devotee_city';

  /// Saves or retrieves the devotee's optional chosen name.
  static Future<void> saveDevoteeName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_devoteeNameKey, name.trim());
    } catch (_) {}
  }

  static Future<String?> getDevoteeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_devoteeNameKey);
    } catch (_) {
      return null;
    }
  }

  /// Saves the user's detected or chosen city for telemetry and offline panchang.
  static Future<void> saveUserCity(String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedCityKey, cityName.trim());
    } catch (_) {}
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  /// Sends a lightweight heartbeat to track downloads, DAU, and city analytics.
  /// When [isVip] is omitted, the locally stored premium status is reported.
  static Future<void> sendAnonymousPing({
    required String locale,
    bool? isVip,
    String? userName,
    String? city,
  }) async {
    if (backendUrl.trim().isEmpty) return;

    try {
      final deviceId = await getAnonymousDeviceId();
      final prefs = await SharedPreferences.getInstance();

      final effectiveName = (userName ?? prefs.getString(_devoteeNameKey) ?? '').trim();
      final effectiveCity = (city ?? prefs.getString(_cachedCityKey) ?? '').trim();

      if (city != null && city.isNotEmpty) {
        await prefs.setString(_cachedCityKey, city.trim());
      }

      final adminGranted = prefs.getBool(_adminGrantedVipKey) ?? false;
      final storedPremium = prefs.getBool(_premiumKey) ?? false;
      // Only report paid VIP; admin-granted VIP is tracked separately on the server.
      final effectiveVip = isVip ?? (storedPremium && !adminGranted);

      final url = Uri.parse('${backendUrl.trim()}/api/v1/telemetry/ping');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'platform': _platformName,
              'appVersion': appVersion,
              'locale': locale,
              'isVip': effectiveVip,
              if (effectiveName.isNotEmpty) 'userName': effectiveName,
              if (effectiveCity.isNotEmpty) 'city': effectiveCity,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          await _applyAdminVipGrant(prefs, decoded['vipGranted'] == true);
        }
      }
    } catch (_) {
      // Non-blocking fire-and-forget
    }
  }

  /// Applies complimentary VIP granted from the admin dashboard.
  /// Revoking only removes premium that the admin granted, never a paid unlock.
  static Future<void> _applyAdminVipGrant(SharedPreferences prefs, bool granted) async {
    final wasGranted = prefs.getBool(_adminGrantedVipKey) ?? false;
    final hasPremium = prefs.getBool(_premiumKey) ?? false;
    if (granted && !hasPremium) {
      await prefs.setBool(_premiumKey, true);
      await prefs.setBool(_adminGrantedVipKey, true);
    } else if (!granted && wasGranted) {
      await prefs.setBool(_premiumKey, false);
      await prefs.setBool(_adminGrantedVipKey, false);
    }
  }

  /// Registers this device's FCM token so the admin dashboard can target it.
  static Future<void> registerPushToken(String token, {required bool enabled}) async {
    if (backendUrl.trim().isEmpty || _isFlutterTest) return;
    try {
      final deviceId = await getAnonymousDeviceId();
      await http
          .post(
            Uri.parse('${backendUrl.trim()}/api/v1/telemetry/push-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'token': token,
              'enabled': enabled,
              'platform': _platformName,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static final bool _isFlutterTest = () {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }();

  static final List<Map<String, dynamic>> _pendingEvents = [];
  static Timer? _flushTimer;

  /// Records an anonymous feature-usage event (e.g. `aarti_open`) for the admin dashboard.
  /// Events are batched and sent a few seconds later; failures are silently dropped.
  static void trackEvent(String name, {String? item, Map<String, dynamic>? props}) {
    if (backendUrl.trim().isEmpty || _isFlutterTest) return;
    _pendingEvents.add({
      'name': name,
      'props': {...?props, if (item != null && item.isNotEmpty) 'item': item},
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
    if (_pendingEvents.length >= 20) {
      _flushEvents();
    } else {
      _flushTimer ??= Timer(const Duration(seconds: 5), _flushEvents);
    }
  }

  static Future<void> _flushEvents() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingEvents.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_pendingEvents);
    _pendingEvents.clear();
    try {
      final deviceId = await getAnonymousDeviceId();
      await http
          .post(
            Uri.parse('${backendUrl.trim()}/api/v1/telemetry/event'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'deviceId': deviceId, 'events': batch}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Analytics must never affect the devotee's experience.
    }
  }

  /// Attempts to fetch cached horoscope reading from the Hetzner backend.
  static Future<HoroscopeReading?> fetchCachedHoroscope({
    required Rashi rashi,
    required String period,
    required String langCode,
  }) async {
    if (backendUrl.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('${backendUrl.trim()}/api/v1/horoscope').replace(
        queryParameters: {
          'rashi': rashi.id,
          'period': period,
          'lang': langCode,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('reading')) {
          final readingMap = decoded['reading'] as Map<String, dynamic>;
          final dateText = decoded['cachedDate']?.toString() ?? '';
          return HoroscopeReading.fromJson(
            readingMap,
            rashiId: rashi.id,
            period: period,
            dateText: dateText,
            isAiGenerated: true,
          );
        }
      }
    } catch (_) {
      // Server error or timeout -> fall back to client calculation
    }
    return null;
  }

  /// Attempts to fetch cached Vedic Panchang from the Hetzner backend.
  static Future<PanchangData?> fetchCachedPanchang({
    required DateTime date,
    required String cityId,
    required String cityName,
    required String langCode,
  }) async {
    if (backendUrl.trim().isEmpty) return null;

    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('${backendUrl.trim()}/api/v1/panchang').replace(
        queryParameters: {
          'city': cityId,
          'date': dateStr,
          'lang': langCode,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('panchang')) {
          final panchangMap = decoded['panchang'] as Map<String, dynamic>;
          return PanchangData.fromJson(
            panchangMap,
            date: date,
            cityName: cityName,
            isAiGenerated: true,
          );
        }
      }
    } catch (_) {
      // Server error or timeout -> fall back to local high-precision math
    }
    return null;
  }
}
