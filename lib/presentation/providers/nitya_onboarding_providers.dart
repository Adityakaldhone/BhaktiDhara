import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics/analytics_service.dart';
import '../../domain/logic/ishta_devta.dart';
import '../../services/aarti_reminder_service.dart';
import '../../services/backend_service.dart';
import '../../services/push_notification_service.dart';

/// The devotee's Ishta Devta ([BhaktiDeity.key]) picked on first launch.
class IshtaDevtaNotifier extends StateNotifier<String?> {
  IshtaDevtaNotifier() : super(null) {
    _load();
  }

  static const _key = kIshtaPrefsKey;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (mounted && saved != null) state = saved;
    } catch (_) {}
  }

  Future<void> select(String deityKey, {String source = 'onboarding'}) async {
    state = deityKey;
    BackendService.trackEvent(
      'ishta_selected',
      item: deityKey,
      props: {'source': source},
    );
    AnalyticsService.logFunnelEvent(
      FunnelEvent.ishtaSelected,
      parameters: {'deity': deityKey, 'source': source},
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, deityKey);
    } catch (_) {}
  }
}

final ishtaDevtaProvider = StateNotifierProvider<IshtaDevtaNotifier, String?>(
  (ref) => IshtaDevtaNotifier(),
);

/// Daily aarti reminder switches, persisted and scheduled on-device.
class AartiRemindersNotifier extends StateNotifier<AartiReminderSettings> {
  AartiRemindersNotifier() : super(const AartiReminderSettings()) {
    _load();
  }

  Future<void> _load() async {
    final saved = await AartiReminderService.load();
    if (mounted) state = saved;
  }

  /// Applies [next], asking for notification permission only when a reminder
  /// is being switched on and permission is missing. Returns whether the
  /// reminders that are on can actually be delivered.
  Future<bool> update(
    AartiReminderSettings next, {
    required String lang,
    required String source,
    String? aartiId,
  }) async {
    final previous = state;
    state = next;

    var deliverable = true;
    if (next.any) {
      deliverable = await PushNotificationService.checkPermissionGranted() ||
          await PushNotificationService.requestNotificationPermission();
    }

    void track(String slot, bool was, bool now) {
      if (was == now) return;
      BackendService.trackEvent(
        now ? 'reminder_enabled' : 'reminder_disabled',
        item: slot,
        props: {'source': source, 'permission': deliverable},
      );
      if (now) {
        AnalyticsService.logFunnelEvent(
          FunnelEvent.reminderEnabled,
          parameters: {'slot': slot, 'source': source},
        );
      }
    }

    track('evening', previous.evening, next.evening);
    track('kakad', previous.kakad, next.kakad);

    await AartiReminderService.save(next, lang: lang, aartiId: aartiId);
    return deliverable;
  }
}

final aartiRemindersProvider =
    StateNotifierProvider<AartiRemindersNotifier, AartiReminderSettings>(
  (ref) => AartiRemindersNotifier(),
);
