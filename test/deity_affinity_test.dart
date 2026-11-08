import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/repositories/deity_affinity_repository.dart';
import 'package:nitya_aarti/domain/logic/deity_affinity_ranker.dart';
import 'package:nitya_aarti/presentation/providers/deity_affinity_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 8, 7, 0);
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;

  group('DeityAffinityRanker', () {
    test('a single open does not promote a deity', () {
      final top = DeityAffinityRanker.rankTop(
        {'Lord Ganesha': DeityUsage(openTimes: [ago(const Duration(hours: 1))])},
        const [],
        now,
      );
      expect(top, isEmpty);
    });

    test('two opens in a week or one real session promotes', () {
      final top = DeityAffinityRanker.rankTop(
        {
          'Lord Ganesha': DeityUsage(openTimes: [
            ago(const Duration(days: 2)),
            ago(const Duration(hours: 1)),
          ]),
          'Lord Hanuman': DeityUsage(sessionTimes: [ago(const Duration(hours: 2))]),
        },
        const [],
        now,
      );
      expect(top, containsAll(['Lord Ganesha', 'Lord Hanuman']));
    });

    test('activity older than two weeks decays out of the top band', () {
      final top = DeityAffinityRanker.rankTop(
        {
          'Lord Shiva': DeityUsage(
            openTimes: [ago(const Duration(days: 20)), ago(const Duration(days: 19))],
            sessionTimes: [ago(const Duration(days: 19))],
          ),
        },
        const ['Lord Shiva'],
        now,
      );
      expect(top, isEmpty);
    });

    test('incumbent keeps first slot unless clearly overtaken', () {
      final daily = DeityUsage(sessionTimes: [
        ago(const Duration(days: 2)),
        ago(const Duration(hours: 3)),
      ]);
      final festival = DeityUsage(
        openTimes: [ago(const Duration(hours: 1))],
        sessionTimes: [
          ago(const Duration(days: 2)),
          ago(const Duration(hours: 1)),
        ],
      );
      final usage = {'Lord Ganesha': daily, 'Goddess Durga': festival};

      expect(
        DeityAffinityRanker.rankTop(usage, const [], now).first,
        'Goddess Durga',
      );
      expect(
        DeityAffinityRanker.rankTop(usage, const ['Lord Ganesha'], now).first,
        'Lord Ganesha',
      );
    });

    test('applyTopBand only moves promoted deities and keeps the rest in order', () {
      final result = DeityAffinityRanker.applyTopBand(
        ['A', 'B', 'C', 'D', 'E'],
        ['D', 'B'],
        (s) => s,
      );
      expect(result, ['D', 'B', 'A', 'C', 'E']);
    });
  });

  group('DeityAffinityNotifier', () {
    late DateTime clock;

    ProviderContainer makeContainer() {
      final container = ProviderContainer(overrides: [
        deityAffinityClockProvider.overrideWithValue(() => clock),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      clock = now;
    });

    test('short visits are ignored and two-minute dwell counts as a session', () async {
      final container = makeContainer();
      final notifier = container.read(deityAffinityProvider.notifier);

      await notifier.recordSession('Lord Hanuman', const Duration(seconds: 5));
      expect(container.read(deityAffinityProvider).usage, isEmpty);

      await notifier.recordSession('Lord Hanuman', const Duration(minutes: 2));
      final usage = container.read(deityAffinityProvider).usage['Lord Hanuman']!;
      expect(usage.sessionTimes, hasLength(1));
      expect(usage.dwellSeconds, 120);
    });

    test('repeat opens within 30 seconds count once', () async {
      final container = makeContainer();
      final notifier = container.read(deityAffinityProvider.notifier);

      await notifier.recordOpen('Lord Ganesha');
      clock = now.add(const Duration(seconds: 10));
      await notifier.recordOpen('Lord Ganesha');
      expect(
        container.read(deityAffinityProvider).usage['Lord Ganesha']!.openTimes,
        hasLength(1),
      );
    });

    test('top band changes only on refresh and survives restart', () async {
      final container = makeContainer();
      final notifier = container.read(deityAffinityProvider.notifier);

      await notifier.recordSession('Gayatri', const Duration(minutes: 3));
      expect(container.read(deityAffinityProvider).top, isEmpty);

      await notifier.refreshTop();
      expect(container.read(deityAffinityProvider).top, ['Goddess Gayatri']);

      final saved = await DeityAffinityRepository().load();
      expect(saved.top, ['Goddess Gayatri']);
      expect(saved.usage['Goddess Gayatri']!.sessionTimes, hasLength(1));
    });
  });
}
