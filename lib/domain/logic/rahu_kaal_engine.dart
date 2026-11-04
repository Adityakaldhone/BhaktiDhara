import 'package:intl/intl.dart';

/// Computes Rahu Kaal, Gulika Kaal and Yamaganda from sunrise/sunset.
///
/// The daytime is divided into 8 equal parts. Each weekday has a specific
/// slot assigned to Rahu Kaal and Gulika Kaal by Vedic tradition.
class RahuKaalEngine {
  /// Rahu Kaal slot number (1–8) for each weekday.
  /// Index: 0=Sunday, 1=Monday, ... 6=Saturday.
  /// Slot 1 = first 1/8 of daytime from sunrise.
  static const List<int> rahuSlot = [4, 2, 7, 5, 6, 3, 8];

  /// Gulika Kaal slot number (1–8) for each weekday.
  static const List<int> gulikaSlot = [7, 6, 5, 4, 3, 2, 1];

  /// Yamaganda slot number (1–8) for each weekday.
  static const List<int> yamagandaSlot = [5, 4, 3, 2, 1, 7, 6];

  /// Returns (start, end) in local DateTime for Rahu Kaal.
  ///
  /// [sunriseLocal] and [sunsetLocal] are wall-clock local times.
  /// [weekday] follows Dart's convention: 1=Monday ... 7=Sunday.
  static (DateTime, DateTime) rahuKaal(
    DateTime sunriseLocal,
    DateTime sunsetLocal,
    int weekday,
  ) {
    return _slot(sunriseLocal, sunsetLocal, _weekdayIndex(weekday), rahuSlot);
  }

  /// Returns (start, end) in local DateTime for Gulika Kaal.
  static (DateTime, DateTime) gulikaKaal(
    DateTime sunriseLocal,
    DateTime sunsetLocal,
    int weekday,
  ) {
    return _slot(sunriseLocal, sunsetLocal, _weekdayIndex(weekday), gulikaSlot);
  }

  /// Returns (start, end) in local DateTime for Yamaganda.
  static (DateTime, DateTime) yamaganda(
    DateTime sunriseLocal,
    DateTime sunsetLocal,
    int weekday,
  ) {
    return _slot(sunriseLocal, sunsetLocal, _weekdayIndex(weekday), yamagandaSlot);
  }

  /// Format as "HH:MM - HH:MM" string.
  static String format(DateTime start, DateTime end, String lang) {
    if (lang == 'en') {
      final fmt = DateFormat('h:mm a');
      return '${fmt.format(start)} – ${fmt.format(end)}';
    } else {
      final fmt = DateFormat('HH:mm');
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }
  }

  // ── Internals ───────────────────────────────────────────────────────────

  /// Converts Dart weekday (1=Mon…7=Sun) to index 0=Sun…6=Sat.
  static int _weekdayIndex(int dartWeekday) {
    // Dart: 1=Mon,2=Tue,...,6=Sat,7=Sun
    // Target: 0=Sun,1=Mon,...,6=Sat
    return dartWeekday % 7;
  }

  static (DateTime, DateTime) _slot(
    DateTime sunriseLocal,
    DateTime sunsetLocal,
    int dayIndex,
    List<int> slotTable,
  ) {
    final totalMs =
        sunsetLocal.millisecondsSinceEpoch - sunriseLocal.millisecondsSinceEpoch;
    final partMs = totalMs ~/ 8;
    final slot = slotTable[dayIndex]; // 1-indexed
    final startMs =
        sunriseLocal.millisecondsSinceEpoch + (slot - 1) * partMs;
    final endMs = startMs + partMs;
    return (
      DateTime.fromMillisecondsSinceEpoch(startMs),
      DateTime.fromMillisecondsSinceEpoch(endMs),
    );
  }
}

