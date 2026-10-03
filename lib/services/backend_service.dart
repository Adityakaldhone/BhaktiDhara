import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_remote_config.dart';
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

  static Future<String>? _appVersionFuture;

  /// Installed version name (e.g. "1.0.6"), read from the platform.
  static Future<String> getAppVersion() => _appVersionFuture ??= () async {
        try {
          return (await PackageInfo.fromPlatform()).version;
        } catch (_) {
          return '0.0.0';
        }
      }();

  static const _anonIdKey = 'anon_device_id';
  static const _premiumKey = 'is_bhaktidhara_premium_member';
  static const _adminGrantedVipKey = 'vip_granted_by_admin';

  static const _keychain = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static Future<String>? _deviceIdFuture;

  /// Persistent anonymous 128-bit device ID (32 hex chars).
  /// Collects ZERO personal information (no phone, no email, no name, no Google account).
  ///
  /// Android: SHA-256 of the system Android ID, so it survives reinstalls and
  /// "Clear data". iOS: random ID mirrored to the Keychain, which outlives an
  /// uninstall. Older Android installs that still hold a random ID are moved
  /// to the Android ID once the backend confirms their records were re-keyed.
  static Future<String> getAnonymousDeviceId() =>
      _deviceIdFuture ??= _resolveDeviceId();

  static Future<String> _resolveDeviceId() async {
    try {
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}
      final saved = prefs?.getString(_anonIdKey);
      final hasSaved = saved != null && saved.isNotEmpty;

      Future<void> persist(String id) async {
        try {
          await prefs?.setString(_anonIdKey, id);
        } catch (_) {}
      }

      if (!kIsWeb && Platform.isAndroid) {
        final androidDeviceId = await _hashedAndroidId();
        if (androidDeviceId != null) {
          if (hasSaved && saved != androidDeviceId) {
            if (!await _migrateDeviceIdOnServer(saved, androidDeviceId)) {
              return saved;
            }
          }
          if (saved != androidDeviceId) await persist(androidDeviceId);
          return androidDeviceId;
        }
      }

      if (!kIsWeb && Platform.isIOS) {
        var deviceId = hasSaved ? saved : null;
        try {
          final keychainId = await _keychain.read(key: _anonIdKey);
          deviceId ??= (keychainId != null && keychainId.isNotEmpty) ? keychainId : null;
          deviceId ??= _randomDeviceId();
          if (keychainId != deviceId) {
            await _keychain.write(key: _anonIdKey, value: deviceId);
          }
        } catch (_) {
          deviceId ??= _randomDeviceId();
        }
        if (!hasSaved) await persist(deviceId);
        return deviceId;
      }

      if (hasSaved) return saved;
      final deviceId = _randomDeviceId();
      await persist(deviceId);
      return deviceId;
    } catch (_) {
      return _randomDeviceId();
    }
  }

  static Future<String?> _hashedAndroidId() async {
    try {
      final androidId = await const AndroidId().getId();
      if (androidId == null || androidId.isEmpty) return null;
      // Hashed so the raw system identifier never leaves the device.
      final digest = sha256.convert(utf8.encode('bhaktidhara:$androidId'));
      return digest.toString().substring(0, 32);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _migrateDeviceIdOnServer(String oldId, String newId) async {
    if (backendUrl.trim().isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/api/v1/device/migrate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'oldDeviceId': oldId, 'newDeviceId': newId}),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _randomDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // UUID v4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
              'appVersion': await getAppVersion(),
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

  static const _remoteConfigKey = 'remote_app_config_v2';

  /// Last config loaded from cache or server. Read by code without a
  /// Riverpod ref (push-tap routing, backend calls during maintenance).
  static AppRemoteConfig remoteConfig = const AppRemoteConfig();

  /// Config saved from the last successful fetch, or defaults (everything on).
  static Future<AppRemoteConfig> loadCachedRemoteConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_remoteConfigKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          remoteConfig = AppRemoteConfig.fromJson(decoded);
        }
      }
    } catch (_) {}
    return remoteConfig;
  }

  /// Fetches `/api/v1/config`; on failure returns the cached config.
  static Future<AppRemoteConfig> fetchRemoteConfig() async {
    if (backendUrl.trim().isEmpty || _isFlutterTest) return remoteConfig;
    try {
      final response = await http
          .get(Uri.parse('${backendUrl.trim()}/api/v1/config'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          remoteConfig = AppRemoteConfig.fromJson(decoded);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_remoteConfigKey, jsonEncode(remoteConfig.toJson()));
        }
      }
    } catch (_) {
      // Keep the cached config; features stay on by default.
    }
    return remoteConfig;
  }

  /// Live announcements for [locale]; empty when offline.
  static Future<List<AppAnnouncement>> fetchAnnouncements(String locale) async {
    if (backendUrl.trim().isEmpty || _isFlutterTest) return const [];
    try {
      final uri = Uri.parse('${backendUrl.trim()}/api/v1/announcements')
          .replace(queryParameters: {'locale': locale});
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final list = decoded is Map ? decoded['announcements'] : null;
        if (list is List) {
          return list.map(AppAnnouncement.fromJson).whereType<AppAnnouncement>().toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  /// Attempts to fetch cached horoscope reading from the Hetzner backend.
  static Future<HoroscopeReading?> fetchCachedHoroscope({
    required Rashi rashi,
    required String period,
    required String langCode,
  }) async {
    if (backendUrl.trim().isEmpty || remoteConfig.maintenanceMode) return null;

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
    if (backendUrl.trim().isEmpty || remoteConfig.maintenanceMode) return null;

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

  /// Consults the Hetzner Vedic AI backend for personalized answers to user's question.
  static Future<VedicAiConsultation?> consultVedicAi({
    required Rashi rashi,
    required String question,
    required String langCode,
    String? initial,
  }) async {
    if (backendUrl.trim().isEmpty || remoteConfig.maintenanceMode) return null;

    try {
      final uri = Uri.parse('${backendUrl.trim()}/api/v1/vedic-ai/consult');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'rashi': rashi.id,
              'question': question,
              'lang': langCode,
              if (initial != null && initial.isNotEmpty) 'initial': initial,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('result')) {
          final resultMap = decoded['result'] as Map<String, dynamic>;
          return VedicAiConsultation.fromJson(resultMap);
        }
      }
    } catch (_) {
      // Backend error or timeout -> fall back to client AI or local engine
    }
    return null;
  }
}

