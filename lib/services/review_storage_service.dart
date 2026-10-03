import 'package:shared_preferences/shared_preferences.dart';

/// Persists engagement metrics and review prompt state so the review system
/// can make smart decisions about when (and whether) to nudge the devotee.
///
/// All keys are prefixed with `review_` to avoid collisions with other
/// SharedPreferences consumers in the app.
class ReviewStorageService {
  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const _keyHasRated = 'review_has_rated';
  static const _keyLastPromptEpoch = 'review_last_prompt_epoch';
  static const _keyPromptCount = 'review_prompt_count';
  static const _keyAartiCount = 'review_aarti_completed_count';
  static const _keyJaapMalaCount = 'review_jaap_mala_count';
  static const _keyCardShareCount = 'review_card_share_count';
  static const _keyFirstOpenEpoch = 'review_first_open_epoch';
  static const _keyDistinctDays = 'review_distinct_open_days';
  static const _keyLastOpenDate = 'review_last_open_date';
  static const _keyDismissedVersion = 'review_dismissed_version';
  static const _keyFeedbackSent = 'review_feedback_sent';

  final SharedPreferences _prefs;
  ReviewStorageService(this._prefs);

  // ── Rated flag ───────────────────────────────────────────────────────────
  /// True once the user positively rated (4–5 stars) or clicked
  /// "Already Rated".  Once set, soft prompts never appear again.
  bool get hasRated => _prefs.getBool(_keyHasRated) ?? false;
  Future<void> setHasRated() => _prefs.setBool(_keyHasRated, true);

  // ── Feedback sent flag ───────────────────────────────────────────────────
  bool get feedbackSent => _prefs.getBool(_keyFeedbackSent) ?? false;
  Future<void> setFeedbackSent() => _prefs.setBool(_keyFeedbackSent, true);

  // ── Engagement counters ──────────────────────────────────────────────────
  int get aartiCount => _prefs.getInt(_keyAartiCount) ?? 0;
  Future<void> incrementAartiCount() =>
      _prefs.setInt(_keyAartiCount, aartiCount + 1);

  int get jaapMalaCount => _prefs.getInt(_keyJaapMalaCount) ?? 0;
  Future<void> incrementJaapMalaCount() =>
      _prefs.setInt(_keyJaapMalaCount, jaapMalaCount + 1);

  int get cardShareCount => _prefs.getInt(_keyCardShareCount) ?? 0;
  Future<void> incrementCardShareCount() =>
      _prefs.setInt(_keyCardShareCount, cardShareCount + 1);

  // ── Open-day tracking ────────────────────────────────────────────────────
  int get distinctOpenDays => _prefs.getInt(_keyDistinctDays) ?? 0;

  /// Call once per app launch.  Increments the counter only if the calendar
  /// date changed since the last call.
  Future<void> recordAppOpen() async {
    final today = _todayKey();
    final lastDate = _prefs.getString(_keyLastOpenDate);

    // First ever open
    if (_prefs.getInt(_keyFirstOpenEpoch) == null) {
      await _prefs.setInt(
        _keyFirstOpenEpoch,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (lastDate != today) {
      await _prefs.setString(_keyLastOpenDate, today);
      await _prefs.setInt(_keyDistinctDays, distinctOpenDays + 1);
    }
  }

  // ── Prompt cooldown ──────────────────────────────────────────────────────
  int get promptCount => _prefs.getInt(_keyPromptCount) ?? 0;

  DateTime? get lastPromptDate {
    final ms = _prefs.getInt(_keyLastPromptEpoch);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> recordPromptShown() async {
    await _prefs.setInt(
      _keyLastPromptEpoch,
      DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setInt(_keyPromptCount, promptCount + 1);
  }

  /// Returns true if at least [cooldownDays] have elapsed since the last
  /// prompt was shown (or no prompt has ever been shown).
  bool isCooldownPassed({int cooldownDays = 25}) {
    final last = lastPromptDate;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= cooldownDays;
  }

  // ── Version-aware dismiss ────────────────────────────────────────────────
  String? get dismissedVersion => _prefs.getString(_keyDismissedVersion);
  Future<void> setDismissedVersion(String version) =>
      _prefs.setString(_keyDismissedVersion, version);

  // ── Helpers ──────────────────────────────────────────────────────────────
  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }
}
