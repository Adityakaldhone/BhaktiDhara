import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/grahan/grahan_engine.dart';
import 'panchang_provider.dart';

List<GrahanEvent> _computeUpcoming((double, double, int, int) args) {
  final (lat, lon, fromMs, toMs) = args;
  return GrahanEngine().between(
    DateTime.fromMillisecondsSinceEpoch(fromMs, isUtc: true),
    DateTime.fromMillisecondsSinceEpoch(toMs, isUtc: true),
    latitude: lat,
    longitude: lon,
  );
}

/// Eclipses from yesterday through the next five years, for the Panchang city.
final upcomingGrahanProvider = FutureProvider.autoDispose<List<GrahanEvent>>((ref) {
  final city = ref.watch(selectedPanchangCityProvider);
  final now = DateTime.now().toUtc();
  final from = now.subtract(const Duration(days: 1));
  final to = DateTime.utc(now.year + 5, now.month, now.day);
  return compute(
    _computeUpcoming,
    (city.latitude, city.longitude, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch),
  );
});

const _remindersKey = 'grahan_reminders_v1';

class GrahanRemindersNotifier extends StateNotifier<Set<String>> {
  GrahanRemindersNotifier() : super(const {}) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_remindersKey) ?? const []).toSet();
  }

  Future<void> set(String id, {required bool enabled}) async {
    state = enabled ? {...state, id} : ({...state}..remove(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_remindersKey, state.toList());
  }
}

/// Ids of eclipses the user asked to be reminded about.
final grahanRemindersProvider =
    StateNotifierProvider<GrahanRemindersNotifier, Set<String>>(
  (ref) => GrahanRemindersNotifier(),
);
