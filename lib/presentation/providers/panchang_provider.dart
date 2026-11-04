import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tithi_engine/tithi_engine.dart';

import '../../domain/entities/panchang.dart';
import '../../domain/entities/panchang_city.dart';
import '../../services/gemini_panchang_service.dart';
import '../../services/location_service.dart';
import '../../services/tithi_engine_service.dart';
import 'locale_provider.dart';

/// Swiss-Ephemeris-verified tithi / festival engine shared app-wide.
final tithiEngineServiceProvider = Provider<TithiEngineService>((ref) {
  return TithiEngineService();
});

/// Provider for the Gemini Panchang Service singleton.
final geminiPanchangServiceProvider = Provider<GeminiPanchangService>((ref) {
  return GeminiPanchangService(engine: ref.watch(tithiEngineServiceProvider));
});

/// Engine view of the selected day: live tithi, accuracy tier, observances.
final tithiDaySnapshotProvider =
    FutureProvider.autoDispose<TithiDaySnapshot?>((ref) async {
  final engine = ref.watch(tithiEngineServiceProvider);
  final date = ref.watch(selectedPanchangDateProvider);
  final city = ref.watch(selectedPanchangCityProvider);
  try {
    await engine.preloadYear(city, date.year);
    return engine.day(date, city, now: DateTime.now());
  } catch (_) {
    return null;
  }
});

/// Next festivals and vrats from the selected day for the selected city.
final upcomingObservancesProvider =
    FutureProvider.autoDispose<List<FestivalDate>>((ref) async {
  final engine = ref.watch(tithiEngineServiceProvider);
  final date = ref.watch(selectedPanchangDateProvider);
  final city = ref.watch(selectedPanchangCityProvider);
  try {
    await Future.wait([
      engine.preloadYear(city, date.year),
      engine.preloadYear(city, date.year + 1),
    ]);
    return engine.upcoming(city, from: date, count: 8);
  } catch (_) {
    return const [];
  }
});

/// Provider for the Location Service.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for the currently selected city (defaults to Pune, auto-detects on first launch).
final selectedPanchangCityProvider = StateProvider<PanchangCity>((ref) {
  return kDefaultCity;
});

/// Async provider to trigger automatic user location detection.
final autoDetectLocationProvider = FutureProvider<PanchangCity>((ref) async {
  final service = ref.watch(locationServiceProvider);
  final detected = await service.detectCurrentCity();
  ref.read(selectedPanchangCityProvider.notifier).state = detected;
  return detected;
});

/// Provider for the currently selected date in the Panchang (defaults to today).
final selectedPanchangDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Counter to trigger forced refresh from Gemini AI.
final panchangRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// Async provider for the active day and city's Vedic Panchang data.
final currentPanchangDataProvider =
    FutureProvider.autoDispose<PanchangData>((ref) async {
  final service = ref.watch(geminiPanchangServiceProvider);
  final date = ref.watch(selectedPanchangDateProvider);
  final city = ref.watch(selectedPanchangCityProvider);
  final langCode = ref.watch(localeProvider).languageCode;
  final refreshCount = ref.watch(panchangRefreshTriggerProvider);

  return service.getPanchang(
    date: date,
    city: city,
    langCode: langCode,
    forceRefresh: refreshCount > 0,
  );
});
