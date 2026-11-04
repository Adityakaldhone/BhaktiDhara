import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  /// Once downloaded, a "Restart" snackbar lets the user install it.
  static Future<bool> tryPlayStoreFlexibleUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.installStatus == InstallStatus.downloaded) {
        _showRestartPrompt();
        return true;
      }
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.flexibleUpdateAllowed) {
        return _downloadFlexible();
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Play Store flexible update error (normal in debug/sideload): $e');
    }
    return false;
  }

  /// Days an update may sit unapplied before the immediate (blocking) flow is used.
  static const int _immediateAfterStaleDays = 7;

  /// Priority (0-5, set per release via the Play Developer API) at or above
  /// which the immediate flow is used.
  static const int _immediatePriority = 4;

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool _checking = false;
  static bool _downloading = false;

  /// Automatic update check, run on launch and on every resume:
  /// - resumes an interrupted immediate update,
  /// - prompts to install an already downloaded flexible update,
  /// - uses the immediate flow for high-priority or stale updates,
  /// - otherwise downloads silently in the background (flexible flow).
  static Future<void> checkForUpdateAutomatically() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_checking || _downloading) return;
    _checking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
      if (info.installStatus == InstallStatus.downloaded) {
        _showRestartPrompt();
        return;
      }
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      final stale = (info.clientVersionStalenessDays ?? 0) >= _immediateAfterStaleDays;
      final urgent = info.updatePriority >= _immediatePriority;
      if ((stale || urgent) && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        unawaited(_downloadFlexible());
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Auto update check error (normal in debug/sideload): $e');
    } finally {
      _checking = false;
    }
  }

  static Future<bool> _downloadFlexible() async {
    if (_downloading) return true;
    _downloading = true;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        _showRestartPrompt();
        return true;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Flexible download error: $e');
    } finally {
      _downloading = false;
    }
    return false;
  }

  static void _showRestartPrompt() {
    final messenger = scaffoldMessengerKey.currentState;
    final context = scaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) return;

    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final (message, action) = switch (lang) {
      'hi' => ('नया अपडेट डाउनलोड हो गया है।', 'रीस्टार्ट'),
      'mr' => ('नवीन अपडेट डाउनलोड झाले आहे.', 'रीस्टार्ट'),
      _ => ('A new update has been downloaded.', 'Restart'),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(days: 1),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: action,
            onPressed: () => InAppUpdate.completeFlexibleUpdate(),
          ),
        ),
      );
  }
}
