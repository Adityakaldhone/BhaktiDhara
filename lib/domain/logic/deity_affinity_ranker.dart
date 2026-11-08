import 'dart:math' as math;

/// A devotee's history with one deity, used to rank the Sacred Collection.
///
/// Timestamps are epoch milliseconds, oldest first.
class DeityUsage {
  final List<int> openTimes;
  final List<int> sessionTimes;
  final int dwellSeconds;

  const DeityUsage({
    this.openTimes = const [],
    this.sessionTimes = const [],
    this.dwellSeconds = 0,
  });

  DeityUsage copyWith({
    List<int>? openTimes,
    List<int>? sessionTimes,
    int? dwellSeconds,
  }) {
    return DeityUsage(
      openTimes: openTimes ?? this.openTimes,
      sessionTimes: sessionTimes ?? this.sessionTimes,
      dwellSeconds: dwellSeconds ?? this.dwellSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'o': openTimes,
        's': sessionTimes,
        'd': dwellSeconds,
      };

  factory DeityUsage.fromJson(Map<String, dynamic> json) {
    List<int> ints(Object? v) =>
        v is List ? v.whereType<num>().map((n) => n.toInt()).toList() : [];
    return DeityUsage(
      openTimes: ints(json['o']),
      sessionTimes: ints(json['s']),
      dwellSeconds: (json['d'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Decides which deities earn the top of the Sacred Collection.
///
/// A deity is promoted only after a habit forms (repeat opens or a real
/// aarti session), and an incumbent keeps its slot unless clearly overtaken,
/// so the list stays familiar from day to day.
class DeityAffinityRanker {
  DeityAffinityRanker._();

  static const int topBandSize = 3;

  /// Foreground time on an aarti that counts as a real session.
  static const Duration meaningfulDwell = Duration(minutes: 2);

  /// Visits shorter than this are treated as accidental taps.
  static const Duration minCountedDwell = Duration(seconds: 15);

  /// Re-opening the same deity within this window counts once.
  static const Duration repeatOpenWindow = Duration(seconds: 30);

  static const int historyCap = 30;
  static const double _promoteMargin = 1.2;

  static int _countSince(List<int> times, DateTime now, Duration window) {
    final cutoff = now.subtract(window).millisecondsSinceEpoch;
    return times.where((t) => t >= cutoff).length;
  }

  static bool isEligible(DeityUsage usage, DateTime now) {
    return _countSince(usage.openTimes, now, const Duration(days: 7)) >= 2 ||
        _countSince(usage.sessionTimes, now, const Duration(days: 14)) >= 1;
  }

  static double score(DeityUsage usage, DateTime now) {
    final opens7 = _countSince(usage.openTimes, now, const Duration(days: 7));
    final sessions7 =
        _countSince(usage.sessionTimes, now, const Duration(days: 7));
    final sessions30 =
        _countSince(usage.sessionTimes, now, const Duration(days: 30));

    var recency = 0.0;
    if (usage.sessionTimes.isNotEmpty) {
      final last = DateTime.fromMillisecondsSinceEpoch(usage.sessionTimes.last);
      if (last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        recency = 3;
      } else if (now.difference(last) <= const Duration(days: 7)) {
        recency = 1;
      }
    }

    return 4.0 * sessions7 +
        (sessions30 - sessions7) +
        2.0 * opens7 +
        math.min(usage.dwellSeconds / 300, 5) +
        recency;
  }

  /// Ordered deity keys for the top band, at most [topBandSize].
  static List<String> rankTop(
    Map<String, DeityUsage> usage,
    List<String> previousTop,
    DateTime now,
  ) {
    final scores = <String, double>{
      for (final e in usage.entries)
        if (isEligible(e.value, now)) e.key: score(e.value, now),
    };

    int previousIndex(String key) {
      final i = previousTop.indexOf(key);
      return i == -1 ? previousTop.length : i;
    }

    final pool = scores.keys.toList()
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        if (byScore != 0) return byScore;
        final byPrevious = previousIndex(a).compareTo(previousIndex(b));
        return byPrevious != 0 ? byPrevious : a.compareTo(b);
      });

    final result = <String>[];
    final slots = math.min(topBandSize, pool.length);
    for (var slot = 0; slot < slots; slot++) {
      final best = pool.first;
      final incumbent = slot < previousTop.length ? previousTop[slot] : null;
      final keepIncumbent = incumbent != null &&
          incumbent != best &&
          pool.contains(incumbent) &&
          scores[best]! < scores[incumbent]! * _promoteMargin;
      final pick = keepIncumbent ? incumbent : best;
      result.add(pick);
      pool.remove(pick);
    }
    return result;
  }

  /// Moves the first item of each [top] deity to the front, in [top] order,
  /// leaving every other item in its original position relative to the rest.
  static List<T> applyTopBand<T>(
    List<T> items,
    List<String> top,
    String Function(T item) keyOf,
  ) {
    if (top.isEmpty) return items;
    final remaining = List<T>.from(items);
    final promoted = <T>[];
    for (final key in top) {
      final index = remaining.indexWhere((item) => keyOf(item) == key);
      if (index != -1) promoted.add(remaining.removeAt(index));
    }
    return [...promoted, ...remaining];
  }
}
