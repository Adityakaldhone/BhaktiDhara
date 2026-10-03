import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../domain/entities/panchang_city.dart';

/// Service for detecting user's current city via Device GPS or IP fallback.
class LocationService {
  /// In-memory cached detected city to avoid repeated battery/network hits.
  static PanchangCity? _cachedCity;

  /// Detects the user's current location city.
  ///
  /// - If [requestPermission] is false (default), it will only use GPS if already
  ///   granted by the user; otherwise it falls back to instant IP Geolocation (zero permissions).
  /// - If [forceGps] is true, it ignores any cached city and re-queries the device GPS.
  Future<PanchangCity> detectCurrentCity({
    bool requestPermission = false,
    bool forceGps = false,
  }) async {
    if (!forceGps && _cachedCity != null) {
      return _cachedCity!;
    }

    // 1. Try Device GPS (Geolocator)
    try {
      final gpsCity = await _detectViaGps(requestPermission: requestPermission);
      if (gpsCity != null) {
        _cachedCity = gpsCity;
        return gpsCity;
      }
    } catch (_) {
      // Continue to IP fallback
    }

    // 2. Try IP Geolocation (Zero-permission, instant)
    try {
      final ipCity = await _detectViaIp();
      if (ipCity != null) {
        _cachedCity = ipCity;
        return ipCity;
      }
    } catch (_) {
      // Fall through to default
    }

    // 3. Graceful fallback
    _cachedCity = kDefaultCity;
    return kDefaultCity;
  }

  Future<PanchangCity?> _detectViaGps({bool requestPermission = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestPermission) {
        // Do NOT pop up a dialog during background auto-detection!
        return null;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 4),
        accuracy: LocationAccuracy.low,
      ),
    );

    return findClosestCity(position.latitude, position.longitude);
  }

  Future<PanchangCity?> _detectViaIp() async {
    final response = await http
        .get(Uri.parse('http://ip-api.com/json'))
        .timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] == 'success') {
        final lat = (data['lat'] as num).toDouble();
        final lon = (data['lon'] as num).toDouble();
        final cityName = data['city']?.toString() ?? '';
        final region = data['regionName']?.toString() ?? '';

        // Check if there is an exact or close match in our curated list
        final matched = kPopularPanchangCities.firstWhere(
          (c) => c.nameEn.toLowerCase() == cityName.toLowerCase() ||
                 c.id.toLowerCase() == cityName.toLowerCase(),
          orElse: () => findClosestCity(lat, lon, fallbackName: cityName, fallbackRegion: region),
        );
        return matched;
      }
    }
    return null;
  }

  /// Finds the geographically closest city from our curated list.
  PanchangCity findClosestCity(
    double lat,
    double lon, {
    String? fallbackName,
    String? fallbackRegion,
  }) {
    PanchangCity closest = kDefaultCity;
    double minDistance = double.infinity;

    for (final city in kPopularPanchangCities) {
      final dLat = city.latitude - lat;
      final dLon = city.longitude - lon;
      final dist = sqrt(dLat * dLat + dLon * dLon);
      if (dist < minDistance) {
        minDistance = dist;
        closest = city;
      }
    }

    // If within ~1.2 degrees (~130 km), return the matched curated city
    if (minDistance < 1.2) {
      return closest;
    }

    // Otherwise, construct a custom city with user's detected coordinates
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return PanchangCity(
        id: fallbackName.toLowerCase().replaceAll(' ', '_'),
        nameMr: fallbackName,
        nameHi: fallbackName,
        nameEn: fallbackName,
        stateOrCountry: fallbackRegion ?? 'भारत',
        latitude: lat,
        longitude: lon,
      );
    }

    return closest;
  }
}
