import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/core/theme/theme.dart';
import 'package:nitya_aarti/data/datasources/jaap_mantra_catalog.dart';
import 'package:nitya_aarti/domain/entities/jaap_progress.dart';
import 'package:nitya_aarti/presentation/providers/jaap_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/jaap_counter_screen.dart';
import 'package:nitya_aarti/presentation/screens/jaap_stats_screen.dart';
import 'package:nitya_aarti/presentation/widgets/jaap/jaap_dashboard_card.dart';
import 'package:nitya_aarti/services/jaap_chant_engine.dart';
import 'package:nitya_aarti/services/jaap_feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'jaap_logic_test.dart' show FakeClock, InMemoryJaapRepository;

class SilentFeedback extends JaapFeedbackService {
  final List<JaapTapOutcome> outcomes = [];

  @override
  Future<void> onTap(JaapTapResult result, JaapProgress settings) async {
    outcomes.add(result.outcome);
  }

  @override
  Future<void> onUndo(JaapProgress settings) async {}
}

class FakeChantEngine implements ChantAudioEngine {
  String? asset;
  int? repetitions;
  int left = 0;
  bool paused = false;
  bool stopped = false;
  void Function()? _onRepetition;
  void Function()? _onFinished;

  @override
  Future<void> start({
    required String asset,
    required int repetitions,
    required void Function() onRepetition,
    required void Function() onFinished,
  }) async {
    this.asset = asset;
    this.repetitions = repetitions;
    left = repetitions;
    stopped = false;
    _onRepetition = onRepetition;
    _onFinished = onFinished;
  }

  void playRepetitions(int n) {
    for (var i = 0; i < n && left > 0; i++) {
      _onRepetition!();
      left--;
      if (left == 0) _onFinished!();
    }
  }

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  Future<void> stop() async => stopped = true;

  @override
  void dispose() {}
}

void main() {
  late FakeClock clock;
  late InMemoryJaapRepository repo;
  late SilentFeedback feedback;
  late FakeChantEngine engine;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = FakeClock(DateTime(2026, 9, 28, 7));
    feedback = SilentFeedback();
    engine = FakeChantEngine();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget home, {
    String lang = 'en',
    Size size = const Size(420, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => Locale(lang)),
          jaapProvider.overrideWith(
            (ref) => JaapNotifier(repo, clock: clock.call),
          ),
          jaapFeedbackProvider.overrideWithValue(feedback),
          chantAudioEngineProvider.overrideWithValue(engine),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapBead(WidgetTester tester) async {
    clock.advance();
    await tester.tap(find.byKey(const ValueKey('jaap-tap-zone')));
    await tester.pump();
  }

  String countText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('jaap-count'))).data!;

  testWidgets('first-time user goes through onboarding then reaches the counter',
      (tester) async {
    repo = InMemoryJaapRepository();
    await pumpScreen(tester, const JaapCounterScreen());

    expect(find.text('Welcome to Naam Jaap 🙏'), findsOneWidget);
    await tester.tap(find.text('Lord Ganesha'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('How many malas each day?'), findsOneWidget);
    await tester.tap(find.text('3 malas'));
    await tester.pump();
    await tester.tap(find.text('Begin 🙏'));
    await tester.pumpAndSettle();

    expect(repo.stored.mantraId, 'ganesha');
    expect(repo.stored.dailyGoalMalas, 3);
    expect(find.text('ॐ गं गणपतये नमः'), findsOneWidget);
    expect(find.text('Tap anywhere to begin'), findsOneWidget);
    expect(countText(tester), '0');
  });

  testWidgets('tapping counts beads and undo removes one', (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
    await pumpScreen(tester, const JaapCounterScreen());

    for (var i = 0; i < 5; i++) {
      await tapBead(tester);
    }
    expect(countText(tester), '5');
    expect(feedback.outcomes, List.filled(5, JaapTapOutcome.bead));

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(countText(tester), '4');
    expect(repo.stored.lifetimeCount, 4);
  });

  testWidgets('completing the daily goal shows Sankalp Purna and Done exits',
      (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(
      mantraId: 'shri_ram',
      dailyLog: {'2026-09-28': 107},
      lifetimeCount: 107,
    ));
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('en')),
          jaapProvider.overrideWith((ref) => JaapNotifier(repo, clock: clock.call)),
          jaapFeedbackProvider.overrideWithValue(feedback),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JaapCounterScreen()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(countText(tester), '0');

    await tapBead(tester);
    await tester.pumpAndSettle();

    expect(feedback.outcomes.last, JaapTapOutcome.goalComplete);
    expect(find.text('Sankalp Purna'), findsOneWidget);
    expect(find.text('1 day streak'), findsWidgets);
    expect(find.text('108 jaaps complete! 🌸'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(JaapCounterScreen), findsNothing);
    expect(repo.stored.completedDays, {'2026-09-28'});
  });

  testWidgets('ring restarts when reopening the counter or choosing a mantra',
      (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
    await pumpScreen(tester, const Scaffold(body: JaapDashboardCard()));

    await tester.tap(find.byType(JaapDashboardCard));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tapBead(tester);
    }
    expect(countText(tester), '5');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(JaapDashboardCard));
    await tester.pumpAndSettle();
    expect(countText(tester), '0');
    expect(find.text('Tap anywhere to begin'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tapBead(tester);
    }
    expect(countText(tester), '3');

    await tester.tap(find.text('Shri Ram'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lord Shiva'));
    await tester.pumpAndSettle();
    expect(countText(tester), '0');
    expect(find.text('ॐ नमः शिवाय'), findsOneWidget);

    expect(repo.stored.countOn('2026-09-28'), 8);
    expect(repo.stored.lifetimeCount, 8);
  });

  testWidgets('chant along credits one bead per audio repetition', (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'shri_ram'));
    await pumpScreen(tester, const JaapCounterScreen());
    await tapBead(tester);
    await tapBead(tester);

    await tester.tap(find.text('Chant along with audio 🎧'));
    await tester.pump();
    expect(engine.asset, 'sounds/jaap/shri_ram.m4a');
    expect(engine.repetitions, 106);
    expect(find.text('Chant along — the beads move on their own'), findsOneWidget);

    engine.playRepetitions(3);
    await tester.pump();
    expect(countText(tester), '5');

    await tapBead(tester);
    expect(countText(tester), '5', reason: 'manual taps are paused during audio');

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(engine.paused, isTrue);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(engine.paused, isFalse);

    engine.playRepetitions(103);
    await tester.pumpAndSettle();
    expect(feedback.outcomes.last, JaapTapOutcome.goalComplete);
    expect(find.text('Sankalp Purna'), findsOneWidget);
    await tester.tap(find.text('Keep chanting'));
    await tester.pumpAndSettle();

    expect(find.text('Chant along with audio 🎧'), findsOneWidget);
    expect(repo.stored.countOn('2026-09-28'), 108);
    expect(repo.stored.audioCountOn('2026-09-28'), 106);
    expect(repo.stored.audioLifetimeCount, 106);
  });

  testWidgets('stop ends chant along and keeps credited beads', (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'om_namah_shivaya'));
    await pumpScreen(tester, const JaapCounterScreen());

    await tester.tap(find.text('Chant along with audio 🎧'));
    await tester.pump();
    engine.playRepetitions(10);
    await tester.pump();
    await tester.tap(find.text('Stop'));
    await tester.pump();

    expect(engine.stopped, isTrue);
    expect(countText(tester), '10');
    expect(repo.stored.audioCountOn('2026-09-28'), 10);
    await tapBead(tester);
    expect(countText(tester), '11');
  });

  testWidgets('premium mantra audio opens the paywall for free users',
      (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(mantraId: 'gayatri'));
    await pumpScreen(tester, const JaapCounterScreen(), size: const Size(600, 1200));

    await tester.tap(find.text('Chant along with audio 🎧'));
    await tester.pumpAndSettle();

    expect(engine.asset, isNull);
    expect(find.text('BhaktiDhara Premium'), findsOneWidget);
  });

  testWidgets('dashboard card shows streak and today progress in Marathi',
      (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(
      mantraId: 'shri_ram',
      dailyGoalMalas: 3,
      dailyLog: {'2026-09-28': 108},
      completedDays: {'2026-09-26', '2026-09-27'},
    ));
    await pumpScreen(
      tester,
      const Scaffold(body: JaapDashboardCard()),
      lang: 'mr',
    );

    expect(find.text('📿 नामजप'), findsOneWidget);
    expect(find.text('आज: 1 / 3 माळ'), findsOneWidget);
    expect(find.text('सलग 2 दिवस'), findsOneWidget);
    expect(find.text('जप सुरू ठेवा 🙏'), findsOneWidget);
  });

  testWidgets('stats screen shows streak, lifetime and milestones', (tester) async {
    repo = InMemoryJaapRepository(const JaapProgress(
      mantraId: 'shri_ram',
      lifetimeCount: 240000,
      dailyLog: {'2026-09-28': 324},
      completedDays: {'2026-09-27', '2026-09-28'},
      bestStreak: 31,
    ));
    await pumpScreen(tester, const JaapStatsScreen());

    expect(find.text('My Sadhana'), findsOneWidget);
    expect(find.text('2.4 Lakh'), findsOneWidget);
    expect(find.text('31'), findsWidgets);
    expect(find.textContaining('324 jaap'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Milestones'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('Next milestone: 1 Crore'), findsOneWidget);
  });

  test('JaapMantraCatalog contains all required mantras from user request', () {
    const requiredIds = [
      'radha',
      'swami_samarth',
      'shri_ram',
      'ganesha',
      'om_namah_shivaya',
      'vasudevaya',
      'jai_shri_ram',
      'hare_krishna',
      'om_namo_narayanaya',
      'gayatri',
      'shani_mantra',
    ];

    for (final id in requiredIds) {
      final mantra = JaapMantraCatalog.byId(id);
      expect(mantra.id, id, reason: 'Mantra $id must exist');
      expect(mantra.devanagari.isNotEmpty, isTrue);
      expect(mantra.transliteration.isNotEmpty, isTrue);
      expect(mantra.name['mr']?.isNotEmpty, isTrue);
      expect(mantra.name['hi']?.isNotEmpty, isTrue);
      expect(mantra.name['en']?.isNotEmpty, isTrue);
      expect(MandirTheme.getDeityImageAsset(mantra.deity).isNotEmpty, isTrue);
    }

    final radha = JaapMantraCatalog.byId('radha');
    expect(radha.devanagari, 'राधा राधा');
    expect(radha.transliteration, 'Radha Radha');

    final swami = JaapMantraCatalog.byId('swami_samarth');
    expect(swami.devanagari, 'श्री स्वामी समर्थ');
    expect(swami.transliteration, 'Shri Swami Samarth');

    final narayana = JaapMantraCatalog.byId('om_namo_narayanaya');
    expect(narayana.devanagari, 'ॐ नमो नारायणाय');
    expect(narayana.transliteration, 'Om Namo Narayanaya');

    final shani = JaapMantraCatalog.byId('shani_mantra');
    expect(shani.devanagari, contains('नीलांजन समाभासं'));
    expect(shani.isLong, isTrue);
  });
}
