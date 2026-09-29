import 'package:flutter_riverpod/flutter_riverpod.dart';
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
