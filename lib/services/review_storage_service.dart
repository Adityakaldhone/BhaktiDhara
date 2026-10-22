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

  SharedPreferences? _prefs;
  ReviewStorageService([this._prefs]) {
    if (_prefs == null) {
      SharedPreferences.getInstance().then((p) => _prefs = p);
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Rated flag ───────────────────────────────────────────────────────────
  bool get hasRated => _prefs?.getBool(_keyHasRated) ?? false;
  Future<void> setHasRated() async {
    final p = await _getPrefs();
    await p.setBool(_keyHasRated, true);
  }

  // ── Feedback sent flag ───────────────────────────────────────────────────
  bool get feedbackSent => _prefs?.getBool(_keyFeedbackSent) ?? false;
  Future<void> setFeedbackSent() async {
    final p = await _getPrefs();
    await p.setBool(_keyFeedbackSent, true);
  }

  // ── Engagement counters ──────────────────────────────────────────────────
  int get aartiCount => _prefs?.getInt(_keyAartiCount) ?? 0;
  Future<void> incrementAartiCount() async {
    final p = await _getPrefs();
    await p.setInt(_keyAartiCount, aartiCount + 1);
  }

  int get jaapMalaCount => _prefs?.getInt(_keyJaapMalaCount) ?? 0;
  Future<void> incrementJaapMalaCount() async {
    final p = await _getPrefs();
    await p.setInt(_keyJaapMalaCount, jaapMalaCount + 1);
  }

  int get cardShareCount => _prefs?.getInt(_keyCardShareCount) ?? 0;
  Future<void> incrementCardShareCount() async {
    final p = await _getPrefs();
    await p.setInt(_keyCardShareCount, cardShareCount + 1);
  }

  // ── Open-day tracking ────────────────────────────────────────────────────
  int get distinctOpenDays => _prefs?.getInt(_keyDistinctDays) ?? 0;

  Future<void> recordAppOpen() async {
    final p = await _getPrefs();
    final today = _todayKey();
    final lastDate = p.getString(_keyLastOpenDate);

    // First ever open
    if (p.getInt(_keyFirstOpenEpoch) == null) {
      await p.setInt(
        _keyFirstOpenEpoch,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (lastDate != today) {
      await p.setString(_keyLastOpenDate, today);
      await p.setInt(_keyDistinctDays, distinctOpenDays + 1);
    }
  }

  // ── Prompt cooldown ──────────────────────────────────────────────────────
  int get promptCount => _prefs?.getInt(_keyPromptCount) ?? 0;

  DateTime? get lastPromptDate {
    final ms = _prefs?.getInt(_keyLastPromptEpoch);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> recordPromptShown() async {
    final p = await _getPrefs();
    await p.setInt(
      _keyLastPromptEpoch,
      DateTime.now().millisecondsSinceEpoch,
    );
    await p.setInt(_keyPromptCount, promptCount + 1);
  }

  bool isCooldownPassed({int cooldownDays = 25}) {
    final last = lastPromptDate;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= cooldownDays;
  }

  // ── Version-aware dismiss ────────────────────────────────────────────────
  String? get dismissedVersion => _prefs?.getString(_keyDismissedVersion);
  Future<void> setDismissedVersion(String version) async {
    final p = await _getPrefs();
    await p.setString(_keyDismissedVersion, version);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }
}
