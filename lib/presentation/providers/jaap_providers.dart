import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/jaap_mantra_catalog.dart';
import '../../data/repositories/jaap_repository.dart';
import '../../domain/entities/jaap_mantra.dart';
import '../../domain/entities/jaap_progress.dart';
import '../../domain/entities/jaap_tap_result.dart';
import '../../domain/logic/jaap_streak.dart';
import '../../services/backend_service.dart';
import 'remote_config_provider.dart';

export '../../domain/entities/jaap_tap_result.dart';

/// Immutable snapshot the UI renders from.
class JaapState {
  final bool loaded;
  final JaapProgress progress;
  final String today;
  final bool isPremium;

  /// Beads counted since the counter was opened or the mantra was chosen.
  /// Drives the ring; not persisted. Daily totals and streaks are unaffected.
  final int sessionCount;

  const JaapState({
    required this.loaded,
    required this.progress,
    required this.today,
    required this.isPremium,
    this.sessionCount = 0,
  });

  JaapMantra get mantra => JaapMantraCatalog.byId(progress.mantraId);

  int get todayCount => progress.countOn(today);
  int get beadIndex => sessionCount % JaapProgress.beadsPerMala;
  int get sessionMalas => sessionCount ~/ JaapProgress.beadsPerMala;
  int get malasToday => progress.malasOn(today);
  int get todaySeconds => progress.secondsOn(today);
  int get todayAudioCount => progress.audioCountOn(today);
  bool get goalMetToday => progress.completedDays.contains(today);

  int get currentStreak => JaapStreak.current(
        completed: progress.completedDays,
        protected: progress.protectedDays,
        today: today,
      );

  int get bestStreak =>
      currentStreak > progress.bestStreak ? currentStreak : progress.bestStreak;

  bool get protectorAvailable => JaapStreak.hasProtector(
        day: today,
        protected: progress.protectedDays,
        isPremium: isPremium,
      );

  /// Yesterday was forgiven by a Kshama Din and the user hasn't chanted yet.
  bool get protectorUsedYesterday =>
      todayCount == 0 &&
      progress.protectedDays.contains(JaapCalendar.shift(today, -1));

  /// The user practised before but their streak has lapsed.
  bool get showWelcomeBack =>
      todayCount == 0 &&
      progress.completedDays.isNotEmpty &&
      currentStreak == 0;
}

class JaapNotifier extends StateNotifier<JaapState> {
  static const Duration tapDebounce = Duration(milliseconds: 250);
  static const Duration _maxCountedGap = Duration(seconds: 30);

  final JaapRepository _repository;
  final DateTime Function() _clock;
  final bool Function() _isPremium;

  DateTime? _lastTapAt;
  int _unsavedMs = 0;

  /// Whether each bead of the current session came from audio, so undo can
  /// reverse the right counters.
  final List<bool> _sessionFromAudio = [];

  JaapNotifier(
    this._repository, {
    DateTime Function()? clock,
    bool Function()? isPremium,
  })  : _clock = clock ?? DateTime.now,
        _isPremium = isPremium ?? (() => false),
        super(JaapState(
          loaded: false,
          progress: const JaapProgress(),
          today: JaapCalendar.dayKey((clock ?? DateTime.now)()),
          isPremium: false,
        )) {
    _load();
  }

  Future<void> _load() async {
    final progress = await _repository.load();
    if (!mounted) return;
    _emit(progress, loaded: true);
    refresh();
  }

  /// Re-evaluates the current day: applies a pending goal change and a
  /// Kshama Din for yesterday if eligible. Call on app resume.
  void refresh() {
    if (!state.loaded) return;
    final today = JaapCalendar.dayKey(_clock());
    var p = state.progress;
    var changed = false;

    final pendingFrom = p.pendingGoalFromDay;
    if (p.pendingGoalMalas != null &&
        pendingFrom != null &&
        today.compareTo(pendingFrom) >= 0) {
      p = p.copyWith(
        dailyGoalMalas: p.pendingGoalMalas,
        clearPendingGoal: true,
      );
      changed = true;
    }

    if (p.completedDays.isNotEmpty) {
      final protectable = JaapStreak.protectableDay(
        completed: p.completedDays,
        protected: p.protectedDays,
        today: today,
        isPremium: _isPremium(),
      );
      if (protectable != null) {
        p = p.copyWith(protectedDays: {...p.protectedDays, protectable});
        changed = true;
      }
    }

    _emit(p);
    if (changed) _repository.save(p);
  }

  /// Counts one bead. Returns `null` when the tap is ignored (not loaded,
  /// not onboarded, or a double-tap inside [tapDebounce]).
  ///
  /// [fromAudio] beads come from chant-along playback: they are paced by the
  /// audio (no debounce) and also tallied separately as audio jaaps.
  JaapTapResult? tap({bool fromAudio = false}) {
    if (!state.loaded || !state.progress.isOnboarded) return null;
    final now = _clock();
    final last = _lastTapAt;
    if (!fromAudio && last != null && now.difference(last) < tapDebounce) {
      return null;
    }

    final today = JaapCalendar.dayKey(now);
    if (today != state.today) refresh();

    var p = state.progress;
    final mantraId = p.mantraId!;
    final newCount = p.countOn(today) + 1;
    final newLifetime = p.lifetimeCount + 1;

    final dailySeconds = Map<String, int>.from(p.dailySeconds);
    if (last != null) {
      final gap = now.difference(last);
      if (gap <= _maxCountedGap) {
        _unsavedMs += gap.inMilliseconds;
        final whole = _unsavedMs ~/ 1000;
        if (whole > 0) {
          dailySeconds[today] = (dailySeconds[today] ?? 0) + whole;
          _unsavedMs -= whole * 1000;
        }
      }
    }
    _lastTapAt = now;

    p = p.copyWith(
      dailyLog: {...p.dailyLog, today: newCount},
      dailySeconds: dailySeconds,
      lifetimeCount: newLifetime,
      perMantraTotals: {
        ...p.perMantraTotals,
        mantraId: (p.perMantraTotals[mantraId] ?? 0) + 1,
      },
    );
    if (fromAudio) {
      p = p.copyWith(
        dailyAudioLog: {...p.dailyAudioLog, today: p.audioCountOn(today) + 1},
        audioLifetimeCount: p.audioLifetimeCount + 1,
      );
    }
    _sessionFromAudio.add(fromAudio);

    final newSession = state.sessionCount + 1;
    var outcome = JaapTapOutcome.bead;
    if (newSession % JaapProgress.beadsPerMala == 0) {
      outcome = JaapTapOutcome.malaComplete;
    }
    if (!p.completedDays.contains(today) && newCount >= p.dailyGoalJaaps) {
      final completed = {...p.completedDays, today};
      final streak = JaapStreak.current(
        completed: completed,
        protected: p.protectedDays,
        today: today,
      );
      p = p.copyWith(
        completedDays: completed,
        bestStreak: streak > p.bestStreak ? streak : p.bestStreak,
      );
      outcome = JaapTapOutcome.goalComplete;
    }
    if (newSession % JaapProgress.beadsPerMala == 0) {
      BackendService.trackEvent('jaap_mala_complete', item: state.mantra.id);
    }
    if (outcome == JaapTapOutcome.goalComplete) {
      BackendService.trackEvent('jaap_goal_complete', item: state.mantra.id);
    }

    _emit(p, today: today, sessionCount: newSession);
    _repository.save(p);
    return JaapTapResult(
      outcome,
      milestone: JaapStreak.milestoneCrossed(newLifetime - 1, newLifetime),
    );
  }

  /// Removes the last bead counted in this session. A goal already marked
  /// complete stays complete so a mistaken undo never costs the user their day.
  bool undo() {
    if (!state.loaded || state.sessionCount == 0) return false;
    final today = state.today;
    var p = state.progress;
    final count = p.countOn(today);
    if (count == 0) return false;

    final mantraId = p.mantraId;
    final perMantra = Map<String, int>.from(p.perMantraTotals);
    if (mantraId != null && (perMantra[mantraId] ?? 0) > 0) {
      perMantra[mantraId] = perMantra[mantraId]! - 1;
    }
    p = p.copyWith(
      dailyLog: {...p.dailyLog, today: count - 1},
      lifetimeCount: p.lifetimeCount > 0 ? p.lifetimeCount - 1 : 0,
      perMantraTotals: perMantra,
    );
    final wasAudio =
        _sessionFromAudio.isNotEmpty && _sessionFromAudio.removeLast();
    if (wasAudio && p.audioCountOn(today) > 0) {
      p = p.copyWith(
        dailyAudioLog: {...p.dailyAudioLog, today: p.audioCountOn(today) - 1},
        audioLifetimeCount: p.audioLifetimeCount - 1,
      );
    }
    _lastTapAt = null;
    _emit(p, sessionCount: state.sessionCount - 1);
    _repository.save(p);
    return true;
  }

  /// Starts a fresh round on the ring. Called whenever the counter is opened.
  void startSession() {
    _lastTapAt = null;
    _sessionFromAudio.clear();
    _emit(state.progress, sessionCount: 0);
  }

  Future<void> completeOnboarding({
    required String mantraId,
    required int dailyGoalMalas,
  }) async {
    final p = state.progress.copyWith(
      mantraId: mantraId,
      dailyGoalMalas: dailyGoalMalas,
      clearPendingGoal: true,
    );
    _emit(p);
    await _repository.save(p);
  }

  /// Choosing a mantra always begins a new round on the ring.
  void selectMantra(String mantraId) {
    final p = state.progress.copyWith(mantraId: mantraId);
    _lastTapAt = null;
    _sessionFromAudio.clear();
    _emit(p, sessionCount: 0);
    _repository.save(p);
  }

  /// Changes the daily goal. Applies immediately if the user hasn't chanted
  /// today, otherwise from tomorrow. Returns `true` if applied immediately.
  bool setDailyGoal(int malas) {
    final today = state.today;
    var p = state.progress;
    final appliesNow = p.countOn(today) == 0;
    if (appliesNow) {
      p = p.copyWith(dailyGoalMalas: malas, clearPendingGoal: true);
    } else if (malas == p.dailyGoalMalas) {
      p = p.copyWith(clearPendingGoal: true);
    } else {
      p = p.copyWith(
        pendingGoalMalas: malas,
        pendingGoalFromDay: JaapCalendar.shift(today, 1),
      );
    }
    _emit(p);
    _repository.save(p);
    return appliesNow;
  }

  void updateSettings({
    bool? tickSoundOn,
    bool? bellOn,
    bool? vibrationOn,
    bool? keepScreenOn,
  }) {
    final p = state.progress.copyWith(
      tickSoundOn: tickSoundOn,
      bellOn: bellOn,
      vibrationOn: vibrationOn,
      keepScreenOn: keepScreenOn,
    );
    _emit(p);
    _repository.save(p);
  }

  void _emit(
    JaapProgress progress, {
    bool? loaded,
    String? today,
    int? sessionCount,
  }) {
    state = JaapState(
      loaded: loaded ?? state.loaded,
      progress: progress,
      today: today ?? JaapCalendar.dayKey(_clock()),
      isPremium: _isPremium(),
      sessionCount: sessionCount ?? state.sessionCount,
    );
  }
}

final jaapRepositoryProvider = Provider<JaapRepository>((ref) => JaapRepository());

final jaapProvider = StateNotifierProvider<JaapNotifier, JaapState>((ref) {
  return JaapNotifier(
    ref.watch(jaapRepositoryProvider),
    isPremium: () => ref.read(premiumAccessProvider),
  );
});
