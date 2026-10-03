import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/data/repositories/recent_deities_repository.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Recent Deities Order & SharedPreferences Caching Tests', () {
    test('Opening Siddhnath, then Ganesha, then Siddhnath again properly orders deities and caches to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify initial state is empty
      expect(container.read(recentDeitiesProvider), isEmpty);

      // 1. User opens Siddhanath Aarti card from Sacred Collection
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Siddhanath');

      expect(container.read(recentDeitiesProvider), ['Lord Siddhanath']);
      expect(container.read(pinnedDeityKeyProvider), 'Lord Siddhanath');
      expect(container.read(selectedDeityIndexProvider), 0);

      List<BhaktiDeity> deities = container.read(bhaktiDeitiesProvider);
      expect(deities.first.key, 'Lord Siddhanath');

      // 2. User now opens Ganesha card from Sacred Collection
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Ganesha');

      expect(container.read(recentDeitiesProvider), ['Lord Ganesha', 'Lord Siddhanath']);
      expect(container.read(pinnedDeityKeyProvider), 'Lord Ganesha');
      expect(container.read(selectedDeityIndexProvider), 0);

      deities = container.read(bhaktiDeitiesProvider);
      expect(deities[0].key, 'Lord Ganesha');
      expect(deities[1].key, 'Lord Siddhanath');

      // 3. User again opens Siddhanath card from Sacred Collection
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Siddhanath');

      expect(container.read(recentDeitiesProvider), ['Lord Siddhanath', 'Lord Ganesha']);
      expect(container.read(pinnedDeityKeyProvider), 'Lord Siddhanath');
      expect(container.read(selectedDeityIndexProvider), 0);

      deities = container.read(bhaktiDeitiesProvider);
      expect(deities[0].key, 'Lord Siddhanath');
      expect(deities[1].key, 'Lord Ganesha');

      // 4. Verify SharedPreferences cache has the exact order
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(RecentDeitiesRepository.prefKey);
      expect(cached, ['Lord Siddhanath', 'Lord Ganesha']);
    });

    test('Reloading cached order on app restart maintains Siddhanath 1st and Ganesha 2nd in Bhakti tab', () async {
      // Mock pre-existing cache in SharedPreferences (simulating app relaunch)
      SharedPreferences.setMockInitialValues({
        RecentDeitiesRepository.prefKey: ['Lord Siddhanath', 'Lord Ganesha'],
      });

      final cachedList = await RecentDeitiesRepository.getInitialRecentDeities();
      expect(cachedList, ['Lord Siddhanath', 'Lord Ganesha']);

      final container = ProviderContainer(
        overrides: [
          initialRecentDeitiesProvider.overrideWithValue(cachedList),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(recentDeitiesProvider), ['Lord Siddhanath', 'Lord Ganesha']);

      final deities = container.read(bhaktiDeitiesProvider);
      expect(deities[0].key, 'Lord Siddhanath');
      expect(deities[1].key, 'Lord Ganesha');
      expect(container.read(selectedDeityIndexProvider), 0);
    });

    test('Canonical matching handles deity aliases gracefully', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 'Gayatri' is an alias for 'Goddess Gayatri'
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Gayatri');

      expect(container.read(recentDeitiesProvider), ['Goddess Gayatri']);
      final deities = container.read(bhaktiDeitiesProvider);
      expect(deities.first.key, 'Goddess Gayatri');
    });

    test('Bhakti carousel reset trigger increments on every card open even for same deity', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialTrigger = container.read(bhaktiCarouselResetTriggerProvider);

      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Siddhanath');
      final firstTrigger = container.read(bhaktiCarouselResetTriggerProvider);
      expect(firstTrigger, greaterThan(initialTrigger));

      // Click same deity again
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Siddhanath');
      final secondTrigger = container.read(bhaktiCarouselResetTriggerProvider);
      expect(secondTrigger, greaterThan(firstTrigger));
    });

    testWidgets('Opening a card updates BhajanScreen carousel to display the newly opened deity at 1st index', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BhajanScreen(),
          ),
        ),
      );
      await tester.pump();

      // Initially, Ganesha is first
      expect(container.read(bhaktiDeitiesProvider).first.key, 'Lord Ganesha');
      expect(container.read(selectedDeityIndexProvider), 0);

      // User opens Siddhnath aarti card
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Siddhanath');
      await tester.pump();

      // In the Bhakti tab, Siddhnath is now at index 0 (1st index)
      expect(container.read(bhaktiDeitiesProvider).first.key, 'Lord Siddhanath');
      expect(container.read(selectedDeityIndexProvider), 0);

      // User opens Ganesha card
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Ganesha');
      await tester.pump();

      // Ganesha is 1st, Siddhnath is 2nd
      expect(container.read(bhaktiDeitiesProvider)[0].key, 'Lord Ganesha');
      expect(container.read(bhaktiDeitiesProvider)[1].key, 'Lord Siddhanath');
      expect(container.read(selectedDeityIndexProvider), 0);

      // User opens Siddhnath card again
      await container.read(recentDeitiesProvider.notifier).recordDeityOpened('Lord Siddhanath');
      await tester.pump();

      // Siddhnath is 1st again, Ganesha is 2nd
      expect(container.read(bhaktiDeitiesProvider)[0].key, 'Lord Siddhanath');
      expect(container.read(bhaktiDeitiesProvider)[1].key, 'Lord Ganesha');
      expect(container.read(selectedDeityIndexProvider), 0);
    });
  });
}
