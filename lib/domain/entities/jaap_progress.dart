/// Everything the Naam Jaap feature persists about a user's practice.
///
/// Day keys are `yyyy-MM-dd` strings produced by `JaapCalendar.dayKey`, which
/// uses a 4:00 AM day boundary.
class JaapProgress {
  static const int beadsPerMala = 108;
  static const List<int> goalOptions = [1, 3, 5, 11, 21];

  /// Selected mantra. `null` until the user finishes onboarding.
  final String? mantraId;

  final int dailyGoalMalas;

  /// A goal change made mid-day only applies from [pendingGoalFromDay].
  final int? pendingGoalMalas;
  final String? pendingGoalFromDay;

  final int lifetimeCount;
  final int bestStreak;

  /// Jaap count per day.
  final Map<String, int> dailyLog;

  /// Seconds spent chanting per day.
  final Map<String, int> dailySeconds;

  /// Lifetime jaap count per mantra id.
  final Map<String, int> perMantraTotals;

  /// Jaaps chanted along with audio, per day. Included in [dailyLog] too.
  final Map<String, int> dailyAudioLog;

  /// Lifetime jaaps chanted along with audio. Included in [lifetimeCount].
  final int audioLifetimeCount;

  /// Days on which the daily goal was met.
  final Set<String> completedDays;

  /// Missed days forgiven by a Kshama Din (streak protector).
  final Set<String> protectedDays;

  final bool tickSoundOn;
  final bool bellOn;
  final bool vibrationOn;
  final bool keepScreenOn;

  const JaapProgress({
    this.mantraId,
    this.dailyGoalMalas = 1,
    this.pendingGoalMalas,
    this.pendingGoalFromDay,
    this.lifetimeCount = 0,
    this.bestStreak = 0,
    this.dailyLog = const {},
    this.dailySeconds = const {},
    this.perMantraTotals = const {},
    this.dailyAudioLog = const {},
    this.audioLifetimeCount = 0,
    this.completedDays = const {},
    this.protectedDays = const {},
    this.tickSoundOn = false,
    this.bellOn = true,
    this.vibrationOn = true,
    this.keepScreenOn = true,
  });

  bool get isOnboarded => mantraId != null;

  int get dailyGoalJaaps => dailyGoalMalas * beadsPerMala;

  int countOn(String day) => dailyLog[day] ?? 0;

  int secondsOn(String day) => dailySeconds[day] ?? 0;

  int audioCountOn(String day) => dailyAudioLog[day] ?? 0;

  /// Bead position (0..107) within the current mala for [day].
  int beadIndexOn(String day) => countOn(day) % beadsPerMala;

  int malasOn(String day) => countOn(day) ~/ beadsPerMala;

  JaapProgress copyWith({
    String? mantraId,
    int? dailyGoalMalas,
    int? pendingGoalMalas,
    String? pendingGoalFromDay,
    bool clearPendingGoal = false,
    int? lifetimeCount,
    int? bestStreak,
    Map<String, int>? dailyLog,
    Map<String, int>? dailySeconds,
    Map<String, int>? perMantraTotals,
    Map<String, int>? dailyAudioLog,
    int? audioLifetimeCount,
    Set<String>? completedDays,
    Set<String>? protectedDays,
    bool? tickSoundOn,
    bool? bellOn,
    bool? vibrationOn,
    bool? keepScreenOn,
  }) {
    return JaapProgress(
      mantraId: mantraId ?? this.mantraId,
      dailyGoalMalas: dailyGoalMalas ?? this.dailyGoalMalas,
      pendingGoalMalas: clearPendingGoal
          ? null
          : (pendingGoalMalas ?? this.pendingGoalMalas),
      pendingGoalFromDay: clearPendingGoal
          ? null
          : (pendingGoalFromDay ?? this.pendingGoalFromDay),
      lifetimeCount: lifetimeCount ?? this.lifetimeCount,
      bestStreak: bestStreak ?? this.bestStreak,
      dailyLog: dailyLog ?? this.dailyLog,
      dailySeconds: dailySeconds ?? this.dailySeconds,
      perMantraTotals: perMantraTotals ?? this.perMantraTotals,
      dailyAudioLog: dailyAudioLog ?? this.dailyAudioLog,
      audioLifetimeCount: audioLifetimeCount ?? this.audioLifetimeCount,
      completedDays: completedDays ?? this.completedDays,
      protectedDays: protectedDays ?? this.protectedDays,
      tickSoundOn: tickSoundOn ?? this.tickSoundOn,
      bellOn: bellOn ?? this.bellOn,
      vibrationOn: vibrationOn ?? this.vibrationOn,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'mantraId': mantraId,
        'dailyGoalMalas': dailyGoalMalas,
        'pendingGoalMalas': pendingGoalMalas,
        'pendingGoalFromDay': pendingGoalFromDay,
        'lifetimeCount': lifetimeCount,
        'bestStreak': bestStreak,
        'dailyLog': dailyLog,
        'dailySeconds': dailySeconds,
        'perMantraTotals': perMantraTotals,
        'dailyAudioLog': dailyAudioLog,
        'audioLifetimeCount': audioLifetimeCount,
        'completedDays': completedDays.toList()..sort(),
        'protectedDays': protectedDays.toList()..sort(),
        'tickSoundOn': tickSoundOn,
        'bellOn': bellOn,
        'vibrationOn': vibrationOn,
        'keepScreenOn': keepScreenOn,
      };

  factory JaapProgress.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Object? raw) => raw is Map
        ? raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))
        : const {};
    Set<String> stringSet(Object? raw) =>
        raw is List ? raw.map((e) => e.toString()).toSet() : const {};

    return JaapProgress(
      mantraId: json['mantraId'] as String?,
      dailyGoalMalas: (json['dailyGoalMalas'] as num?)?.toInt() ?? 1,
      pendingGoalMalas: (json['pendingGoalMalas'] as num?)?.toInt(),
      pendingGoalFromDay: json['pendingGoalFromDay'] as String?,
      lifetimeCount: (json['lifetimeCount'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      dailyLog: intMap(json['dailyLog']),
      dailySeconds: intMap(json['dailySeconds']),
      perMantraTotals: intMap(json['perMantraTotals']),
      dailyAudioLog: intMap(json['dailyAudioLog']),
      audioLifetimeCount: (json['audioLifetimeCount'] as num?)?.toInt() ?? 0,
      completedDays: stringSet(json['completedDays']),
      protectedDays: stringSet(json['protectedDays']),
      tickSoundOn: json['tickSoundOn'] as bool? ?? false,
      bellOn: json['bellOn'] as bool? ?? true,
      vibrationOn: json['vibrationOn'] as bool? ?? true,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
    );
  }
}
