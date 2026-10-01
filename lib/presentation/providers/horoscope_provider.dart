import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/horoscope.dart';
import '../../services/gemini_horoscope_service.dart';
import 'locale_provider.dart';

/// Provider for the Gemini Horoscope Service singleton.
final geminiHoroscopeServiceProvider = Provider<GeminiHoroscopeService>((ref) {
  return GeminiHoroscopeService();
});

/// Provider for the currently selected Rashi (defaults to Aries / Mesh).
final selectedRashiProvider = StateProvider<Rashi>((ref) {
  return kAllRashis.first;
});

/// Provider for the currently selected period ('today', 'tomorrow', 'weekly').
final selectedHoroscopePeriodProvider = StateProvider<String>((ref) {
  return 'today';
});

/// Counter to force a refresh from Gemini AI when user taps 'Refresh'.
final horoscopeRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Async provider that fetches the horoscope reading for the active Rashi, period, and language.
final currentHoroscopeReadingProvider =
    FutureProvider.autoDispose<HoroscopeReading>((ref) async {
  final service = ref.watch(geminiHoroscopeServiceProvider);
  final rashi = ref.watch(selectedRashiProvider);
  final period = ref.watch(selectedHoroscopePeriodProvider);
  final langCode = ref.watch(localeProvider).languageCode;
  final refreshCount = ref.watch(horoscopeRefreshTriggerProvider);

  return service.getHoroscope(
    rashi: rashi,
    period: period,
    langCode: langCode,
    forceRefresh: refreshCount > 0,
  );
});

/// Notifier for toggling the daily 6:00 AM Horoscope Curiosity Push notification.
class MorningReminderNotifier extends StateNotifier<bool> {
  static const _prefKey = 'morning_horoscope_push_enabled';

  MorningReminderNotifier() : super(true) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_prefKey) ?? true;
    } catch (_) {}
  }

  Future<void> toggle(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }
}

/// Provider for whether the daily 6:00 AM morning horoscope push reminder is active.
final morningReminderEnabledProvider =
    StateNotifierProvider<MorningReminderNotifier, bool>((ref) {
  return MorningReminderNotifier();
});

