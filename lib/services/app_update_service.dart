import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service responsible for orchestrating app updates:
/// 1. Native Google Play In-App Updates (Immediate / Flexible updates via Play Core API).
/// 2. Direct Store redirection (market:// fallback to https://play.google.com).
class AppUpdateService {
  AppUpdateService._();

  static const String playStorePackage = 'com.kaldhone.bhaktidhara';
  static const String playStoreMarketUrl = 'market://details?id=$playStorePackage';
  static const String playStoreWebUrl = 'https://play.google.com/store/apps/details?id=$playStorePackage';

  /// Opens the Google Play Store (or custom URL if provided).
  /// Tries the native market:// URI first so it opens the Play Store app directly,
  /// with a clean fallback to the web URL.
  static Future<bool> openStore({String? customUrl}) async {
    final target = customUrl?.trim();
    if (target != null && target.isNotEmpty) {
      final uri = Uri.tryParse(target);
      if (uri != null) {
        try {
          if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            return true;
          }
        } catch (e) {
          debugPrint('[AppUpdateService] Failed to open custom url $target: $e');
        }
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final marketUri = Uri.parse(playStoreMarketUrl);
      try {
        if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Market URI launch failed, falling back to web: $e');
      }
    }

    final webUri = Uri.parse(playStoreWebUrl);
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to launch Play Store web URL: $e');
      return false;
    }
  }

  /// Attempts to trigger Google Play's native Immediate Update modal.
  /// Returns `true` if update succeeded, `false` otherwise.
  /// Fails gracefully when running in debug, sideloaded, or on non-Android platforms.
  static Future<bool> tryPlayStoreImmediateUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        return result == AppUpdateResult.success;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Play Store immediate update error (normal in debug/sideload): $e');
    }
    return false;
  }

  /// Attempts to trigger Google Play's native Flexible Update in the background.
  /// If downloaded, immediately finishes the update.
  static Future<bool> tryPlayStoreFlexibleUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Play Store flexible update error (normal in debug/sideload): $e');
    }
    return false;
  }
}
