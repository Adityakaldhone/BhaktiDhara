import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tithi_engine/tithi_engine.dart';

import '../../services/tithi_engine_service.dart';
import 'panchang_provider.dart';

/// Current calendar month (year, month, day=1). Defaults to today's month.
final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Pre-fetched snapshots for all days in the current calendar month.
/// Map key is day-of-month (1-based).
final calendarMonthSnapshotsProvider =
    FutureProvider.autoDispose<Map<int, TithiDaySnapshot>>((ref) async {
  final engine = ref.watch(tithiEngineServiceProvider);
  final city = ref.watch(selectedPanchangCityProvider);
  final month = ref.watch(calendarMonthProvider);

  final year = month.year;
  final monthNum = month.month;

  // Preload the year (and the next if we're near December)
  await engine.preloadYear(city, year);
  if (monthNum == 12) await engine.preloadYear(city, year + 1);

  final daysInMonth = DateTime(year, monthNum + 1, 0).day;
  final Map<int, TithiDaySnapshot> result = {};

  for (int d = 1; d <= daysInMonth; d++) {
    final date = DateTime(year, monthNum, d);
    try {
      result[d] = engine.day(date, city);
    } catch (_) {
      // Skip days that fail (shouldn't happen, but be safe)
    }
  }
  return result;
});

/// All festival dates for the calendar's current year.
final calendarYearObservancesProvider =
    FutureProvider.autoDispose<List<FestivalDate>>((ref) async {
  final engine = ref.watch(tithiEngineServiceProvider);
  final city = ref.watch(selectedPanchangCityProvider);
  final month = ref.watch(calendarMonthProvider);
  final year = month.year;
  await engine.preloadYear(city, year);
  return engine.yearObservances(city, year);
});

/// Snapshot for a specific date (used in day bottom sheet).
final calendarDaySnapshotProvider =
    FutureProvider.autoDispose.family<TithiDaySnapshot?, DateTime>((ref, date) async {
  final engine = ref.watch(tithiEngineServiceProvider);
  final city = ref.watch(selectedPanchangCityProvider);
  try {
    await engine.preloadYear(city, date.year);
    return engine.day(date, city, now: DateTime.now());
  } catch (_) {
    return null;
  }
});
