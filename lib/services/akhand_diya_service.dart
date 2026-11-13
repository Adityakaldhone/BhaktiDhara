import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/bhakti_deity.dart';
import '../domain/logic/akhand_diya.dart';
import '../domain/logic/ishta_devta.dart';
import 'push_notification_service.dart';

/// Persists the Akhand Jyot and keeps its two on-device ghee reminders in
/// step with the last refill.
class AkhandDiyaService {
  AkhandDiyaService._();

  static const lowGheeId = 72000;
  static const lastCallId = 72330;

  static const _refilledKey = 'diya_last_refill_ms';
  static const _legacyRefilledKey = 'diya_last_refilled_at';
  static const _streakKey = 'diya_streak_days';
  static const _streakDateKey = 'diya_last_streak_date';
  static const _graceKey = 'diya_grace_used';
  static const _aartiKey = 'diya_aarti_id';
  static const _introSeenKey = 'diya_intro_seen';

  static Future<AkhandDiyaState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_refilledKey) ?? prefs.getInt(_legacyRefilledKey);
      return AkhandDiyaState(
        lastRefilledAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
        streakDays: prefs.getInt(_streakKey) ?? 0,
        graceUsed: prefs.getBool(_graceKey) ?? false,
      );
    } catch (_) {
      return const AkhandDiyaState();
    }
  }

  /// Saves [state] and replaces any pending reminders. [aartiId] is the
  /// aarti a reminder tap opens.
  static Future<void> save(
    AkhandDiyaState state, {
    required String lang,
    required BhaktiDeity deity,
    String? aartiId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = state.lastRefilledAt;
      if (last != null) {
        await prefs.setInt(_refilledKey, last.millisecondsSinceEpoch);
        await prefs.setString(_streakDateKey, ymd(last));
      }
      await prefs.setInt(_streakKey, state.streakDays);
      await prefs.setBool(_graceKey, state.graceUsed);
      if (aartiId != null && aartiId.isNotEmpty) await prefs.setString(_aartiKey, aartiId);
    } catch (_) {}
    await _schedule(state, lang: lang, deity: deity, aartiId: aartiId);
  }

  /// Re-schedules from saved state with fresh text. Call on every launch so
  /// language and Ishta Devta changes reach pending reminders.
  static Future<void> reapply(String lang) async {
    final state = await load();
    if (!state.everLit) return;
    String? aartiId;
    String? ishtaKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      aartiId = prefs.getString(_aartiKey);
      ishtaKey = prefs.getString(kIshtaPrefsKey);
    } catch (_) {}
    await _schedule(state, lang: lang, deity: ishtaOrDefault(ishtaKey), aartiId: aartiId);
  }

  /// YYYY-MM-DD in device time.
  static String ymd(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  static Future<bool> introSeen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_introSeenKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markIntroSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_introSeenKey, true);
    } catch (_) {}
  }

  static Future<void> _schedule(
    AkhandDiyaState state, {
    required String lang,
    required BhaktiDeity deity,
    String? aartiId,
  }) async {
    await PushNotificationService.cancelReminder(lowGheeId);
    await PushNotificationService.cancelReminder(lastCallId);
    final refilledAt = state.lastRefilledAt;
    final expiry = state.expiresAt;
    if (refilledAt == null || expiry == null) return;

    final times = jyotReminderTimes(refilledAt);
    final name = deity.localizedName(lang);

    final low = lowGheeText(lang, name, expiry.difference(times.first));
    await PushNotificationService.scheduleReminder(
      id: lowGheeId,
      atUtc: times.first.toUtc(),
      title: low.title,
      body: low.body,
      payload: _payload('jyot_low_ghee', aartiId),
      templeBell: true,
    );

    final second = times.second;
    if (second == null) return;
    final last = lastCallText(lang, expiry.difference(second));
    await PushNotificationService.scheduleReminder(
      id: lastCallId,
      atUtc: second.toUtc(),
      title: last.title,
      body: last.body,
      payload: _payload('jyot_last_call', aartiId),
      templeBell: true,
    );
  }

  static Map<String, dynamic> _payload(String campaign, String? aartiId) => {
        'campaignId': campaign,
        if (aartiId != null) ...{'route': 'aarti', 'aartiId': aartiId},
      };

  static ({String title, String body}) lowGheeText(
    String lang,
    String deityName,
    Duration left,
  ) {
    final span = formatGheeDuration(left, lang, coarse: true);
    return switch (lang) {
      'en' => (
          title: '🪔 Ghee is running low in your $deityName Akhand Jyot!',
          body: 'Only $span of ghee left. Do a 1-minute aarti to keep the flame alive.',
        ),
      'mr' => (
          title: '🪔 तुमच्या $deityName अखंड ज्योतीचे तूप कमी होत आहे!',
          body: 'फक्त $span पुरेल इतके तूप शिल्लक आहे. 1 मिनिट आरती करा आणि ज्योत तेवत ठेवा.',
        ),
      _ => (
          title: '🪔 आपकी $deityName अखंड ज्योत का घी कम हो रहा है!',
          body: 'केवल $span का घी शेष है। 1 मिनट की आरती करें और ज्योत को प्रज्वलित रखें।',
        ),
    };
  }

  static ({String title, String body}) lastCallText(String lang, Duration left) {
    final span = formatGheeDuration(left, lang, coarse: true);
    return switch (lang) {
      'en' => (
          title: '⚠️ Your Akhand Jyot goes out in $span!',
          body: 'Come to your mandir and offer ghee in one tap.',
        ),
      'mr' => (
          title: '⚠️ $span मध्ये अखंड ज्योत शांत होईल!',
          body: 'तुमच्या मंदिरात या आणि एका क्लिकमध्ये तूप अर्पण करा.',
        ),
      _ => (
          title: '⚠️ $span में अखंड ज्योत शांत हो जाएगी!',
          body: 'अपने मंदिर में पधारें और एक क्लिक में घी अर्पित करें।',
        ),
    };
  }
}
