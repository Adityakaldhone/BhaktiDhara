import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/providers/panchang_provider.dart';
import 'push_notification_service.dart';

/// Coordinates application permissions (Notifications and Location) cleanly
/// to prevent system prompt collisions on first launch and enforce a strict
/// "Ask once, and if dismissed/denied, ask only one more time" (max 2 prompts) policy.
class AppPermissionService {
  static const String _keyNotificationPromptCount = 'pref_notification_permission_ask_count';
  static const String _keyLocationPromptCount = 'pref_location_permission_ask_count';

  /// Maximum number of times the app will automatically prompt for each permission.
  /// (First launch = 1st prompt. If dismissed/denied, next launch = 2nd and final prompt).
  static const int maxPromptAttempts = 2;

  /// Guard to ensure we only run the startup sequence once per app lifecycle session.
  static bool _hasRunThisSession = false;

  /// Runs the sequential, collision-free startup permission flow.
  ///
  /// Flow:
  /// 1. Waits for the home screen layout & animations to settle (~700ms).
  /// 2. Notification Permission: Prompts if not granted and prompted < 2 times.
  /// 3. Pauses ~600ms so the OS window clears completely.
  /// 4. Location Permission: Prompts if not granted and prompted < 2 times.
  /// 5. If Location is granted, auto-updates the Panchang city via GPS.
  static Future<void> checkAndRequestStartupPermissions(WidgetRef ref) async {
    if (kIsWeb || _hasRunThisSession) return;
    _hasRunThisSession = true;

    try {
      // 1. Give the UI breathing room on launch so initial render is smooth
      await Future<void>.delayed(const Duration(milliseconds: 700));

      final prefs = await SharedPreferences.getInstance();

      // ── Step 1: Notifications ──────────────────────────────────────────
      final notifGranted = await PushNotificationService.checkPermissionGranted();
      final notifPromptCount = prefs.getInt(_keyNotificationPromptCount) ?? 0;

      if (!notifGranted && notifPromptCount < maxPromptAttempts) {
        debugPrint(
          '[AppPermissionService] Prompting notification permission '
          '(Attempt ${notifPromptCount + 1}/$maxPromptAttempts)...',
        );
        await prefs.setInt(_keyNotificationPromptCount, notifPromptCount + 1);
        await PushNotificationService.requestNotificationPermission();

        // Pause to let Android OS Activity window dismiss cleanly
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }

      // ── Step 2: Location (Vedic Panchang Sunrise/Sunset) ────────────────
      if (Platform.isAndroid || Platform.isIOS) {
        var locPermission = await Geolocator.checkPermission();
        final isLocGranted = locPermission == LocationPermission.whileInUse ||
            locPermission == LocationPermission.always;
        final locPromptCount = prefs.getInt(_keyLocationPromptCount) ?? 0;

        if (!isLocGranted &&
            locPermission != LocationPermission.deniedForever &&
            locPromptCount < maxPromptAttempts) {
          debugPrint(
            '[AppPermissionService] Prompting location permission '
            '(Attempt ${locPromptCount + 1}/$maxPromptAttempts)...',
          );
          await prefs.setInt(_keyLocationPromptCount, locPromptCount + 1);
          locPermission = await Geolocator.requestPermission();

          if (locPermission == LocationPermission.whileInUse ||
              locPermission == LocationPermission.always) {
            debugPrint('[AppPermissionService] Location granted! Refreshing Panchang city via GPS...');
            final locationService = ref.read(locationServiceProvider);
            final detectedCity = await locationService.detectCurrentCity(
              forceGps: true,
              requestPermission: false,
            );
            ref.read(selectedPanchangCityProvider.notifier).state = detectedCity;
          }
        }
      }
    } catch (e) {
      debugPrint('[AppPermissionService] Error during permission sequence: $e');
    }
  }

  /// Resets prompt counts (useful for testing or debugging).
  static Future<void> resetPromptCounts() async {
    _hasRunThisSession = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotificationPromptCount);
    await prefs.remove(_keyLocationPromptCount);
  }
}
