import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'review_storage_service.dart';

/// Orchestrates the two-pronged review strategy:
///
/// 1. **Automated soft prompts** — shown after devotional milestones (mala
///    completion, aarti listen, card share) guarded by engagement thresholds,
///    cooldown timers, and a max-lifetime cap.
///
/// 2. **Explicit "Rate Us"** — a permanent tile in the Settings sheet that
///    always launches the Play Store listing directly.
class ReviewService {
  final InAppReview _inAppReview;
  final ReviewStorageService _storage;

  /// The fallback Android application ID used to build Play Store URIs.
  static const String packageId = 'com.kaldhone.bhaktidhara';

  /// Maximum number of soft-prompt popups per install (across all versions).
  static const int _maxLifetimePrompts = 3;

  /// Minimum number of distinct calendar days the app was opened before
  /// any prompt is eligible.
  static const int _minOpenDays = 3;

  /// Minimum aarti completions OR jaap mala completions needed.
  static const int _minAartiCount = 2;
  static const int _minJaapMalaCount = 1;

  /// Cooldown between successive prompts (days).
  static const int _cooldownDays = 25;

  ReviewService(this._storage, [InAppReview? inAppReview])
      : _inAppReview = inAppReview ?? InAppReview.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  //  ELIGIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// In-memory flag ensuring devotee is not prompted multiple times
  /// within the same app session if they dismiss or choose later.
  bool _shownThisSession = false;

  /// Returns `true` if the user is visiting the app for the 2nd time or later.
  bool get isSecondTimeOrMore =>
      _storage.appOpenCount >= 2 || _storage.distinctOpenDays >= 2;

  /// First process after install — no paywall / review popups yet.
  bool get isFirstSession => !isSecondTimeOrMore;

  /// Returns `true` when user opens an aarti and presses back, provided they
  /// haven't given a review previously and are on their 2nd+ visit.
  bool isEligibleForAartiExitPrompt() {
    // 1. Must NOT have rated previously ("until and unless user haven't given review")
    if (_storage.hasRated) return false;

    // 2. Must be second time (or later) on the app
    if (!isSecondTimeOrMore) return false;

    // 3. Do not spam within the same continuous session if already shown
    if (_shownThisSession) return false;

    return true;
  }

  /// Marks that a review prompt was presented during this app session.
  void markPromptShownThisSession() {
    _shownThisSession = true;
  }

  /// Returns `true` when the automated soft prompt should be offered.
  /// This does NOT guarantee the Google Play review sheet will appear —
  /// Google controls that independently.
  bool isEligibleForPrompt() {
    // User has already given a positive rating — never prompt again.
    if (_storage.hasRated) return false;

    // Lifetime cap on soft prompts.
    if (_storage.promptCount >= _maxLifetimePrompts) return false;

    // Cooldown from last prompt (or first ever prompt).
    if (!_storage.isCooldownPassed(cooldownDays: _cooldownDays)) return false;

    // Minimum retention: must have opened on at least N distinct days.
    if (_storage.distinctOpenDays < _minOpenDays) return false;

    // Engagement gate: meaningful devotional activity.
    final isEngaged = _storage.aartiCount >= _minAartiCount ||
        _storage.jaapMalaCount >= _minJaapMalaCount ||
        _storage.cardShareCount >= 2;

    return isEngaged;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Directly triggers Google Play's official native in-app review sheet.
  /// The user sees Google Play's native bottom sheet with 5 stars and submits
  /// directly to Google without leaving the app.
  Future<void> requestInAppReview({bool fallbackToStore = false}) async {
    await _storage.setHasRated();
    try {
      final available = await _inAppReview.isAvailable();
      debugPrint('[ReviewService] Google InAppReview isAvailable: $available');
      if (available) {
        debugPrint('[ReviewService] Launching Google Play review sheet...');
        await _inAppReview.requestReview();
        debugPrint('[ReviewService] Google Play review flow finished.');
      } else if (fallbackToStore) {
        debugPrint('[ReviewService] InAppReview not available; opening Play Store...');
        await openStoreListing();
      }
    } catch (e) {
      debugPrint('[ReviewService] InAppReview error: $e');
      if (fallbackToStore) {
        await openStoreListing();
      }
    }
  }

  /// Opens the Google Play Store listing directly. Used for:
  /// - The "Rate BhaktiDhara" / "Rate Panchang" tile in Settings.
  /// - Fallback when `requestReview()` is unavailable.
  Future<void> openStoreListing([String? customPackageId]) async {
    await _storage.setHasRated();
    final targetId = customPackageId ?? await _resolvePackageId();

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.openStoreListing(appStoreId: targetId);
        return;
      }
    } catch (e) {
      debugPrint('[ReviewService] InAppReview openStoreListing error: $e');
    }

    if (kIsWeb) {
      await _launchWeb(targetId);
      return;
    }

    if (Platform.isAndroid) {
      final marketUri = Uri.parse('market://details?id=$targetId');
      try {
        if (await canLaunchUrl(marketUri)) {
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        // Fall through to web URL
      }
    }

    await _launchWeb(targetId);
  }

  /// Resolves the actual runtime application ID (supports flavors).
  Future<String> _resolvePackageId() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.packageName.isNotEmpty) {
        return info.packageName;
      }
    } catch (_) {}
    return packageId;
  }

  /// Records the prompt-shown event.  Call immediately before presenting
  /// the devotional pre-filter dialog.
  Future<void> recordPromptShown() => _storage.recordPromptShown();

  /// Marks that the user sent negative feedback (1–3 stars path).
  Future<void> recordFeedbackSent() => _storage.setFeedbackSent();

  // ── Engagement trackers (call from feature screens) ────────────────────
  Future<void> trackAartiCompleted() => _storage.incrementAartiCount();
  Future<void> trackJaapMalaCompleted() => _storage.incrementJaapMalaCount();
  Future<void> trackCardShared() => _storage.incrementCardShareCount();
  Future<void> trackAppOpen() => _storage.recordAppOpen();

  // ── Private helpers ────────────────────────────────────────────────────
  Future<void> _launchWeb([String? targetId]) async {
    final id = targetId ?? packageId;
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$id',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
