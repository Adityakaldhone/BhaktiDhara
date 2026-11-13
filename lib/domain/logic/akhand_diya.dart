/// A full refill of ghee keeps the Akhand Jyot burning this long.
const kGheeLife = Duration(hours: 24);

/// A diya that went out can still be relit without losing the streak, once
/// per streak, until this long after the last refill.
const kReviveWindow = Duration(hours: 48);

/// After a refill, the aarti screen offers ghee again only after this gap.
const kOfferingCooldown = Duration(hours: 1);

enum JyotLevel {
  /// 0–12h since refill.
  bright(1.0),

  /// 12–20h.
  medium(0.75),

  /// 20–24h: small flickering flame.
  low(0.45),

  /// Over 24h: unlit wick.
  out(0.0);

  const JyotLevel(this.flameScale);
  final double flameScale;
}

class AkhandDiyaState {
  const AkhandDiyaState({
    this.lastRefilledAt,
    this.streakDays = 0,
    this.graceUsed = false,
  });

  final DateTime? lastRefilledAt;
  final int streakDays;

  /// The current streak already survived one missed day.
  final bool graceUsed;

  bool get everLit => lastRefilledAt != null;

  Duration elapsed(DateTime now) {
    final last = lastRefilledAt;
    if (last == null) return kGheeLife;
    final d = now.difference(last);
    return d.isNegative ? Duration.zero : d;
  }

  DateTime? get expiresAt => lastRefilledAt?.add(kGheeLife);

  /// max(0, (24 − elapsedHours) / 24 × 100).
  double gheePercent(DateTime now) {
    if (!everLit) return 0;
    final left = 1 - elapsed(now).inSeconds / kGheeLife.inSeconds;
    return (left * 100).clamp(0.0, 100.0);
  }

  Duration gheeLeft(DateTime now) {
    final left = kGheeLife - elapsed(now);
    return left.isNegative ? Duration.zero : left;
  }

  JyotLevel level(DateTime now) {
    if (!everLit) return JyotLevel.out;
    final h = elapsed(now).inMinutes / 60;
    if (h < 12) return JyotLevel.bright;
    if (h < 20) return JyotLevel.medium;
    if (h < 24) return JyotLevel.low;
    return JyotLevel.out;
  }

  /// Whether refilling now keeps the current streak going.
  bool streakSurvives(DateTime now) {
    if (!everLit) return false;
    final e = elapsed(now);
    return e < kGheeLife || (!graceUsed && e < kReviveWindow);
  }

  /// The flame is out but a refill still saves a streak worth mentioning.
  bool canRevive(DateTime now) =>
      level(now) == JyotLevel.out && streakSurvives(now) && streakDays >= 2;

  bool acceptsOffering(DateTime now) =>
      !everLit || elapsed(now) >= kOfferingCooldown;

  /// Refills to 100%. The streak counts calendar days with a refill: a second
  /// refill on the same day only tops up the ghee.
  AkhandDiyaState refilled(DateTime now) {
    final last = lastRefilledAt;
    if (last == null) {
      return AkhandDiyaState(lastRefilledAt: now, streakDays: 1);
    }
    final e = elapsed(now);
    if (e < kGheeLife) {
      return AkhandDiyaState(
        lastRefilledAt: now,
        streakDays: _sameDay(last, now) ? streakDays : streakDays + 1,
        graceUsed: graceUsed,
      );
    }
    if (!graceUsed && e < kReviveWindow) {
      return AkhandDiyaState(
        lastRefilledAt: now,
        streakDays: streakDays + 1,
        graceUsed: true,
      );
    }
    return AkhandDiyaState(lastRefilledAt: now, streakDays: 1);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Local (device-time) moments for the two ghee reminders after a refill at
/// [refilledAt]: "ghee running low" and "about to go out". Neither lands
/// between 22:00 and 06:00; [second] is null when it would crowd [first].
({DateTime first, DateTime? second}) jyotReminderTimes(DateTime refilledAt) {
  final expiry = refilledAt.add(kGheeLife);

  var morning = DateTime(refilledAt.year, refilledAt.month, refilledAt.day, 7);
  final earliestMorning = refilledAt.add(const Duration(hours: 8));
  while (morning.isBefore(earliestMorning)) {
    morning = DateTime(morning.year, morning.month, morning.day + 1, 7);
  }
  final low = refilledAt.add(const Duration(hours: 20));
  final first = _outsideNight(low.isBefore(morning) ? low : morning, expiry);

  final second = _outsideNight(
    refilledAt.add(const Duration(hours: 23, minutes: 30)),
    expiry,
  );
  final keepSecond = second.isAfter(first.add(const Duration(hours: 1)));
  return (first: first, second: keepSecond ? second : null);
}

bool _isNight(DateTime t) => t.hour >= 22 || t.hour < 6;

/// Moves a night-time [t] to 06:00 if the diya is still burning then,
/// otherwise back to 21:30 the evening before.
DateTime _outsideNight(DateTime t, DateTime expiry) {
  if (!_isNight(t)) return t;
  final morning = t.hour < 6
      ? DateTime(t.year, t.month, t.day, 6)
      : DateTime(t.year, t.month, t.day + 1, 6);
  if (morning.isBefore(expiry)) return morning;
  return t.hour >= 22
      ? DateTime(t.year, t.month, t.day, 21, 30)
      : DateTime(t.year, t.month, t.day - 1, 21, 30);
}

/// "19 तास 40 मिनिटे" / "19 घंटे 40 मिनट" / "19h 40m". With [coarse],
/// durations of 3h or more drop the minutes.
String formatGheeDuration(Duration d, String lang, {bool coarse = false}) {
  final h = d.inHours;
  var m = d.inMinutes % 60;
  if (coarse && h >= 3) m = 0;
  final hours = switch (lang) {
    'mr' => '$h तास',
    'hi' => '$h घंटे',
    _ => coarse ? '$h ${h == 1 ? 'hour' : 'hours'}' : '${h}h',
  };
  final minutes = switch (lang) {
    'mr' => '$m मिनिटे',
    'hi' => '$m मिनट',
    _ => coarse ? '$m minutes' : '${m}m',
  };
  if (h == 0) return minutes;
  if (m == 0) return hours;
  return '$hours $minutes';
}
