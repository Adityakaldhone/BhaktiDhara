import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/aarti_item.dart';
import 'push_notification_service.dart';

/// Which daily aarti reminders the devotee has switched on.
class AartiReminderSettings {
  const AartiReminderSettings({this.evening = false, this.kakad = false});

  /// 6:30 PM Sandhya aarti.
  final bool evening;

  /// 6:00 AM Kakad aarti.
  final bool kakad;

  bool get any => evening || kakad;

  AartiReminderSettings copyWith({bool? evening, bool? kakad}) =>
      AartiReminderSettings(
        evening: evening ?? this.evening,
        kakad: kakad ?? this.kakad,
      );
}

/// Daily on-device aarti reminders. Local notifications, not FCM, so they
/// fire without network and are never shared with other devices.
class AartiReminderService {
  AartiReminderService._();

  static const eveningId = 71830;
  static const kakadId = 70600;

  static const eveningHour = 18;
  static const eveningMinute = 30;
  static const kakadHour = 6;
  static const kakadMinute = 0;

  static const _eveningKey = 'aarti_reminder_evening';
  static const _kakadKey = 'aarti_reminder_kakad';
  static const _aartiKey = 'aarti_reminder_aarti_id';
  static const _nityaKey = 'bhaktidhara_nitya_aartis_v1';

  static Future<AartiReminderSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AartiReminderSettings(
        evening: prefs.getBool(_eveningKey) ?? false,
        kakad: prefs.getBool(_kakadKey) ?? false,
      );
    } catch (_) {
      return const AartiReminderSettings();
    }
  }

  /// Saves [settings] and (re)schedules or cancels both reminders. [aartiId]
  /// is the aarti a reminder tap opens when no Nitya Aarti is pinned.
  static Future<void> save(
    AartiReminderSettings settings, {
    required String lang,
    String? aartiId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_eveningKey, settings.evening);
      await prefs.setBool(_kakadKey, settings.kakad);
      if (aartiId != null && aartiId.isNotEmpty) {
        await prefs.setString(_aartiKey, aartiId);
      }
    } catch (_) {}
    await reapply(lang);
  }

  /// Re-schedules from saved settings with fresh text and target aarti.
  /// Call on every launch so language changes and new pins are picked up.
  static Future<void> reapply(String lang) async {
    final settings = await load();
    final aarti = await _targetAarti();

    if (settings.evening) {
      final text = eveningText(lang, aarti);
      await PushNotificationService.scheduleDailyReminder(
        id: eveningId,
        hour: eveningHour,
        minute: eveningMinute,
        title: text.title,
        body: text.body,
        payload: _payload('reminder_evening', aarti),
      );
    } else {
      await PushNotificationService.cancelReminder(eveningId);
    }

    if (settings.kakad) {
      final text = kakadText(lang, aarti);
      await PushNotificationService.scheduleDailyReminder(
        id: kakadId,
        hour: kakadHour,
        minute: kakadMinute,
        title: text.title,
        body: text.body,
        payload: _payload('reminder_kakad', aarti),
      );
    } else {
      await PushNotificationService.cancelReminder(kakadId);
    }
  }

  /// First pinned Nitya Aarti, otherwise the aarti saved with the reminder.
  static Future<AartiItem?> _targetAarti() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in prefs.getStringList(_nityaKey) ?? const <String>[]) {
        final item = PushNotificationService.findAartiById(id);
        if (item != null) return item;
      }
      return PushNotificationService.findAartiById(prefs.getString(_aartiKey));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _payload(String campaign, AartiItem? aarti) => {
        'campaignId': campaign,
        if (aarti != null) ...{'route': 'aarti', 'aartiId': aarti.id},
      };

  static ({String title, String body}) eveningText(String lang, AartiItem? aarti) {
    final name = aarti?.localizedTitle(lang);
    return switch (lang) {
      'en' => (
          title: '🪔 Time for Sandhya Aarti',
          body: name == null
              ? 'Light the diya and start your evening aarti in one tap.'
              : '$name — start your evening aarti in one tap.',
        ),
      'mr' => (
          title: '🪔 संध्याकाळच्या आरतीची वेळ झाली',
          body: name == null
              ? 'दिवा लावा आणि एका टॅपमध्ये आरती सुरू करा.'
              : '$name — एका टॅपमध्ये आरती सुरू करा.',
        ),
      _ => (
          title: '🪔 संध्या आरती का समय',
          body: name == null
              ? 'दीया जलाइए और एक टैप में आरती शुरू कीजिए।'
              : '$name — एक टैप में आरती शुरू कीजिए।',
        ),
    };
  }

  static ({String title, String body}) kakadText(String lang, AartiItem? aarti) {
    final name = aarti?.localizedTitle(lang);
    return switch (lang) {
      'en' => (
          title: '🌅 Time for Kakad Aarti',
          body: name == null
              ? 'Begin the day with the Lord’s name.'
              : 'Begin the day with $name.',
        ),
      'mr' => (
          title: '🌅 काकड आरतीची वेळ',
          body: name == null
              ? 'दिवसाची सुरुवात देवाच्या नावाने करा.'
              : 'दिवसाची सुरुवात करा — $name',
        ),
      _ => (
          title: '🌅 काकड़ आरती का समय',
          body: name == null
              ? 'दिन की शुरुआत प्रभु के नाम से कीजिए।'
              : 'दिन की शुरुआत कीजिए — $name',
        ),
    };
  }
}
