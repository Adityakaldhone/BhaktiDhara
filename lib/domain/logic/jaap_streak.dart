/// Date helpers for the Naam Jaap feature.
///
/// A jaap "day" starts at 4:00 AM local time (Brahma muhurta), so someone
/// chanting at 1 AM is still credited to the previous day.
class JaapCalendar {
  static const int dayStartHour = 4;

  static String dayKey(DateTime time) {
    final shifted = time.subtract(const Duration(hours: dayStartHour));
    return _format(shifted.year, shifted.month, shifted.day);
  }

  static DateTime parse(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Built from date components rather than adding hours, so daylight-saving
  /// shifts can never skip or repeat a day.
  static String shift(String key, int days) {
    final d = parse(key);
    final shifted = DateTime(d.year, d.month, d.day + days);
    return _format(shifted.year, shifted.month, shifted.day);
  }

  /// Key of the Monday that starts the week containing [key].
  static String weekKey(String key) {
    final d = parse(key);
    return shift(key, -(d.weekday - DateTime.monday));
  }

  static String monthKey(String key) => key.substring(0, 7);

  static String _format(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-'
      '${m.toString().padLeft(2, '0')}-'
      '${d.toString().padLeft(2, '0')}';
}

/// Pure streak rules (see §9 of docs/features/jaap_mala_counter.md).
class JaapStreak {
  static const List<int> milestones = [
    108,
    1008,
    11000,
    100000,
    125000,
    10000000,
  ];

  /// Consecutive completed days ending today (or yesterday, if today's goal
  /// is not met yet). Protected days bridge the streak but don't add to it.
  /// Days after [today] are ignored so a changed phone clock can't add days.
  static int current({
    required Set<String> completed,
    required Set<String> protected,
    required String today,
  }) {
    var cursor = completed.contains(today)
        ? today
        : JaapCalendar.shift(today, -1);
    var streak = 0;
    while (true) {
      if (completed.contains(cursor)) {
        streak++;
      } else if (!protected.contains(cursor)) {
        break;
      }
      cursor = JaapCalendar.shift(cursor, -1);
    }
    return streak;
  }

  /// Returns yesterday's key if a Kshama Din should be applied to it:
  /// yesterday was missed, the day before was completed, and the user still
  /// has a protector for that period (1 per week premium, 1 per month free).
  static String? protectableDay({
    required Set<String> completed,
    required Set<String> protected,
    required String today,
    required bool isPremium,
  }) {
    final yesterday = JaapCalendar.shift(today, -1);
    final dayBefore = JaapCalendar.shift(today, -2);
    if (completed.contains(yesterday) || protected.contains(yesterday)) {
      return null;
    }
    if (!completed.contains(dayBefore)) return null;
    if (!hasProtector(
      day: yesterday,
      protected: protected,
      isPremium: isPremium,
    )) {
      return null;
    }
    return yesterday;
  }

  static bool hasProtector({
    required String day,
    required Set<String> protected,
    required bool isPremium,
  }) {
    String period(String d) =>
        isPremium ? JaapCalendar.weekKey(d) : JaapCalendar.monthKey(d);
    final target = period(day);
    return !protected.any((p) => period(p) == target);
  }

  /// The milestone crossed when the lifetime count goes from [before] to
  /// [after], if any.
  static int? milestoneCrossed(int before, int after) {
    for (final m in milestones) {
      if (before < m && after >= m) return m;
    }
    return null;
  }

  static int? nextMilestone(int lifetime) {
    for (final m in milestones) {
      if (lifetime < m) return m;
    }
    return null;
  }
}
