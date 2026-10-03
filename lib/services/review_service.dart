import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
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
  final InAppReview _inAppReview = InAppReview.instance;
  final ReviewStorageService _storage;

  /// The Android application ID used to build Play Store URIs.
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

  ReviewService(this._storage);

  // ═══════════════════════════════════════════════════════════════════════════
  //  ELIGIBILITY
  // ═══════════════════════════════════════════════════════════════════════════

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
  /// - The "Rate BhaktiDhara" tile in Settings.
  /// - Fallback when `requestReview()` is unavailable.
  Future<void> openStoreListing() async {
    await _storage.setHasRated();

    if (kIsWeb) {
      await _launchWeb();
      return;
    }

    if (Platform.isAndroid) {
      final marketUri = Uri.parse('market://details?id=$packageId');
      try {
        if (await canLaunchUrl(marketUri)) {
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        // Fall through to web URL
      }
    }

    await _launchWeb();
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
  Future<void> _launchWeb() async {
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageId',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
