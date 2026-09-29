import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/repositories/jaap_repository.dart';
import 'package:nitya_aarti/domain/entities/jaap_progress.dart';
import 'package:nitya_aarti/domain/logic/jaap_streak.dart';
import 'package:nitya_aarti/presentation/jaap/jaap_strings.dart';
import 'package:nitya_aarti/presentation/providers/jaap_providers.dart';

class InMemoryJaapRepository extends JaapRepository {
  JaapProgress stored;
  int saves = 0;

  InMemoryJaapRepository([this.stored = const JaapProgress()]);

  @override
  Future<JaapProgress> load() async => stored;

  @override
  Future<void> save(JaapProgress progress) async {
    stored = progress;
    saves++;
  }
}

class FakeClock {
  DateTime now;
  FakeClock(this.now);

  DateTime call() => now;

  void advance([Duration d = const Duration(seconds: 1)]) => now = now.add(d);
}

Future<JaapNotifier> createNotifier(
  InMemoryJaapRepository repo,
  FakeClock clock, {
  bool premium = false,
}) async {
  final notifier = JaapNotifier(repo, clock: clock.call, isPremium: () => premium);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  group('JaapCalendar', () {
    test('day starts at 4 AM', () {
      expect(JaapCalendar.dayKey(DateTime(2026, 9, 28, 3, 59)), '2026-09-27');
      expect(JaapCalendar.dayKey(DateTime(2026, 9, 28, 4, 0)), '2026-09-28');
      expect(JaapCalendar.dayKey(DateTime(2026, 9, 28, 23, 59)), '2026-09-28');
    });

    test('shift crosses month and year boundaries', () {
      expect(JaapCalendar.shift('2026-03-01', -1), '2026-02-28');
      expect(JaapCalendar.shift('2024-03-01', -1), '2024-02-29');
      expect(JaapCalendar.shift('2026-12-31', 1), '2027-01-01');
    });

    test('weekKey returns the Monday of the week', () {
      expect(JaapCalendar.weekKey('2026-09-28'), '2026-09-28'); // Monday
      expect(JaapCalendar.weekKey('2026-10-04'), '2026-09-28'); // Sunday
    });
  });

  group('JaapStreak.current', () {
    const today = '2026-09-28';

    test('counts consecutive days including today', () {
      final streak = JaapStreak.current(
        completed: {'2026-09-26', '2026-09-27', today},
        protected: {},
        today: today,
      );
      expect(streak, 3);
    });

    test('keeps yesterday\'s streak alive while today is pending', () {
      final streak = JaapStreak.current(
        completed: {'2026-09-26', '2026-09-27'},
        protected: {},
        today: today,
      );
      expect(streak, 2);
    });

    test('a missed day breaks the streak', () {
      final streak = JaapStreak.current(
        completed: {'2026-09-25', '2026-09-26'},
        protected: {},
        today: today,
      );
      expect(streak, 0);
    });

    test('a protected day bridges the streak without adding to it', () {
      final streak = JaapStreak.current(
        completed: {'2026-09-25', '2026-09-26', today},
        protected: {'2026-09-27'},
        today: today,
      );
      expect(streak, 3);
    });

    test('future days from a changed clock are ignored', () {
      final streak = JaapStreak.current(
        completed: {'2026-09-27', '2026-10-05'},
        protected: {},
        today: today,
      );
      expect(streak, 1);
    });
  });

  group('JaapStreak.protectableDay', () {
    const today = '2026-09-28';

    test('forgives a single missed day after a completed day', () {
      final day = JaapStreak.protectableDay(
        completed: {'2026-09-26'},
        protected: {},
        today: today,
        isPremium: false,
      );
      expect(day, '2026-09-27');
    });

    test('does not forgive two missed days', () {
      final day = JaapStreak.protectableDay(
        completed: {'2026-09-25'},
        protected: {},
        today: today,
        isPremium: true,
      );
      expect(day, isNull);
    });

    test('free users get one per month', () {
      final day = JaapStreak.protectableDay(
        completed: {'2026-09-26'},
        protected: {'2026-09-05'},
        today: today,
        isPremium: false,
      );
      expect(day, isNull);
    });

    test('premium users get one per week', () {
      final day = JaapStreak.protectableDay(
        completed: {'2026-09-26'},
        protected: {'2026-09-15'},
        today: today,
        isPremium: true,
      );
      expect(day, '2026-09-27');
    });
  });

  group('Milestones & numbers', () {
    test('detects milestone crossings', () {
      expect(JaapStreak.milestoneCrossed(107, 108), 108);
      expect(JaapStreak.milestoneCrossed(108, 109), isNull);
      expect(JaapStreak.nextMilestone(500), 1008);
    });

    test('formats numbers the Indian way', () {
      expect(JaapStrings.grouped(108000), '1,08,000');
      expect(const JaapStrings('en').compact(240000), '2.4 Lakh');
      expect(const JaapStrings('mr').compact(125000), '1.25 लाख');
      expect(const JaapStrings('hi').compact(10000000), '1 करोड़');
      expect(const JaapStrings('en').compact(1008), '1,008');
    });
  });

  group('JaapProgress JSON', () {
    test('round-trips all fields', () {
      const original = JaapProgress(
        mantraId: 'ganesha',
        dailyGoalMalas: 3,
        pendingGoalMalas: 5,
        pendingGoalFromDay: '2026-09-29',
        lifetimeCount: 1234,
        bestStreak: 9,
        dailyLog: {'2026-09-28': 324},
        dailySeconds: {'2026-09-28': 600},
        perMantraTotals: {'ganesha': 1234},
        completedDays: {'2026-09-27', '2026-09-28'},
        protectedDays: {'2026-09-20'},
        tickSoundOn: true,
        bellOn: false,
        vibrationOn: false,
        keepScreenOn: false,
      );
      final copy = JaapProgress.fromJson(original.toJson());
      expect(copy.toJson(), original.toJson());
    });
  });

  group('JaapNotifier', () {
    late FakeClock clock;

    setUp(() => clock = FakeClock(DateTime(2026, 9, 28, 7)));

    test('ignores taps before onboarding', () async {
      final notifier = await createNotifier(InMemoryJaapRepository(), clock);
      expect(notifier.tap(), isNull);
      expect(notifier.state.todayCount, 0);
    });

    test('debounces taps closer than 250ms', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      expect(notifier.tap(), isNotNull);
      clock.advance(const Duration(milliseconds: 100));
      expect(notifier.tap(), isNull);
      clock.advance(const Duration(milliseconds: 200));
      expect(notifier.tap(), isNotNull);
      expect(notifier.state.todayCount, 2);
    });

    test('completes a mala at 108 and the goal at goal × 108', () async {
      final repo = InMemoryJaapRepository(
        const JaapProgress(mantraId: 'shri_ram', dailyGoalMalas: 2),
      );
      final notifier = await createNotifier(repo, clock);

      final outcomes = <JaapTapOutcome>[];
      for (var i = 0; i < 216; i++) {
        clock.advance();
        outcomes.add(notifier.tap()!.outcome);
      }
      expect(outcomes[106], JaapTapOutcome.bead);
      expect(outcomes[107], JaapTapOutcome.malaComplete);
      expect(outcomes[215], JaapTapOutcome.goalComplete);
      expect(notifier.state.malasToday, 2);
      expect(notifier.state.beadIndex, 0);
      expect(notifier.state.goalMetToday, isTrue);
      expect(notifier.state.currentStreak, 1);
      expect(repo.stored.lifetimeCount, 216);
      expect(repo.stored.perMantraTotals['shri_ram'], 216);
    });

    test('reports the first milestone at 108 jaaps', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      JaapTapResult? last;
      for (var i = 0; i < 108; i++) {
        clock.advance();
        last = notifier.tap();
      }
      expect(last!.milestone, 108);
    });

    test('streak grows across days and tracks best streak', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      for (var day = 0; day < 3; day++) {
        for (var i = 0; i < 108; i++) {
          clock.advance();
          notifier.tap();
        }
        clock.advance(const Duration(days: 1));
        notifier.refresh();
      }
      expect(notifier.state.currentStreak, 3);
      expect(repo.stored.bestStreak, 3);
    });

    test('undo removes one bead but keeps a completed goal', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      for (var i = 0; i < 108; i++) {
        clock.advance();
        notifier.tap();
      }
      expect(notifier.undo(), isTrue);
      expect(notifier.state.todayCount, 107);
      expect(notifier.state.beadIndex, 107);
      expect(notifier.state.goalMetToday, isTrue);
      expect(repo.stored.lifetimeCount, 107);
    });

    test('choosing a mantra or starting a session restarts the ring only',
        () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      for (var i = 0; i < 40; i++) {
        clock.advance();
        notifier.tap();
      }
      notifier.selectMantra('ganesha');
      expect(notifier.state.beadIndex, 0);
      expect(notifier.state.todayCount, 40);
      expect(notifier.undo(), isFalse);

      for (var i = 0; i < 10; i++) {
        clock.advance();
        notifier.tap();
      }
      notifier.startSession();
      expect(notifier.state.beadIndex, 0);
      expect(notifier.state.todayCount, 50);
      expect(repo.stored.perMantraTotals, {'shri_ram': 40, 'ganesha': 10});
    });

    test('a mala completes after 108 beads in the session, not the day',
        () async {
      final repo = InMemoryJaapRepository(const JaapProgress(
        mantraId: 'shri_ram',
        dailyGoalMalas: 3,
        dailyLog: {'2026-09-28': 50},
      ));
      final notifier = await createNotifier(repo, clock);
      JaapTapResult? result;
      for (var i = 0; i < 108; i++) {
        clock.advance();
        result = notifier.tap();
        if (i == 57) expect(result!.outcome, JaapTapOutcome.bead);
      }
      expect(result!.outcome, JaapTapOutcome.malaComplete);
      expect(notifier.state.todayCount, 158);
    });

    test('audio beads skip debounce, are tallied separately, and undo cleanly',
        () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      clock.advance();
      notifier.tap();
      expect(notifier.tap(fromAudio: true), isNotNull);
      expect(notifier.tap(fromAudio: true), isNotNull);

      expect(notifier.state.todayCount, 3);
      expect(notifier.state.todayAudioCount, 2);
      expect(repo.stored.audioLifetimeCount, 2);

      notifier.undo();
      expect(notifier.state.todayAudioCount, 1);
      notifier.undo();
      notifier.undo();
      expect(notifier.state.todayCount, 0);
      expect(notifier.state.todayAudioCount, 0);
      expect(repo.stored.audioLifetimeCount, 0);
    });

    test('undo does nothing when nothing was counted today', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      expect(notifier.undo(), isFalse);
    });

    test('goal change mid-day applies from tomorrow', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      clock.advance();
      notifier.tap();

      expect(notifier.setDailyGoal(5), isFalse);
      expect(notifier.state.progress.dailyGoalMalas, 1);
      expect(notifier.state.progress.pendingGoalMalas, 5);

      clock.advance(const Duration(days: 1));
      notifier.refresh();
      expect(notifier.state.progress.dailyGoalMalas, 5);
      expect(notifier.state.progress.pendingGoalMalas, isNull);
    });

    test('goal change before chanting today applies immediately', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      expect(notifier.setDailyGoal(3), isTrue);
      expect(notifier.state.progress.dailyGoalMalas, 3);
    });

    test('applies a Kshama Din on load after one missed day', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(
        mantraId: 'shri_ram',
        completedDays: {'2026-09-25', '2026-09-26'},
      ));
      final notifier = await createNotifier(repo, clock);
      expect(notifier.state.progress.protectedDays, {'2026-09-27'});
      expect(notifier.state.currentStreak, 2);
      expect(notifier.state.protectorUsedYesterday, isTrue);
      expect(notifier.state.showWelcomeBack, isFalse);
    });

    test('shows a gentle welcome back after a lapsed streak', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(
        mantraId: 'shri_ram',
        completedDays: {'2026-09-20'},
      ));
      final notifier = await createNotifier(repo, clock);
      expect(notifier.state.currentStreak, 0);
      expect(notifier.state.showWelcomeBack, isTrue);
    });

    test('counts chanting time but ignores long pauses', () async {
      final repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
      final notifier = await createNotifier(repo, clock);
      notifier.tap();
      clock.advance(const Duration(seconds: 2));
      notifier.tap();
      clock.advance(const Duration(minutes: 5));
      notifier.tap();
      expect(notifier.state.todaySeconds, 2);
    });
  });
}
