import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/vitthal_songs_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_video_watch_screen.dart';
import 'package:nitya_aarti/presentation/screens/vitthal_songs_screen.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/category_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lord Vitthal YouTube Songs Catalog & Flow Tests', () {
    test('kVitthalSongsCatalog contains all 100 embeddable YouTube songs', () {
      expect(kVitthalSongsCatalog.length, 100);

      for (final song in kVitthalSongsCatalog) {
        expect(song.videoId.isNotEmpty, isTrue);
        expect(song.song.isNotEmpty, isTrue);
        expect(song.channel.isNotEmpty, isTrue);
        expect(song.thumbnailUrl, contains('img.youtube.com/vi/${song.videoId}/hqdefault.jpg'));
      }
    });

    test('deityCategoriesProvider for Lord Vitthal contains song and aarti categories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final categories = container.read(deityCategoriesProvider('Lord Vitthal'));
      expect(categories.contains(BhaktiCategory.song), isTrue);
      expect(categories.contains(BhaktiCategory.aarti), isTrue);
    });

    testWidgets('Tapping Songs button on Bhakti tab for Lord Vitthal opens VitthalSongsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Lord Vitthal'),
            selectedDeityIndexProvider.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'),
              Locale('hi'),
              Locale('mr'),
            ],
            locale: Locale('mr'),
            home: Scaffold(
              body: BhajanScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Songs button ('गाणी') is present for Lord Vitthal
      final songsButtons = find.widgetWithText(BhaktiCategoryButton, 'गाणी');
      expect(songsButtons, findsWidgets);

      // Tap Songs button
      await tester.tap(songsButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // VitthalSongsScreen must be pushed
      expect(find.byType(VitthalSongsScreen), findsOneWidget);

      // Verify search input field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify category pills are visible
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Vitthal Bhaktigeet'), findsOneWidget);

      // Verify rank 1 song card is displayed
      expect(find.text('Bhakta Pundalika Saathi Ubha Rahila Vitevari'), findsOneWidget);
    });

    testWidgets('VitthalSongsScreen allows searching and selecting a song to open DeityVideoWatchScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: VitthalSongsScreen(),
        ),
      );
      await tester.pump();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Kanada Raja');
      await tester.pump();

      // Verify filtered result
      expect(find.text('Kanada Raja Pandharicha'), findsOneWidget);

      // Tap on the song card
      await tester.tap(find.text('Kanada Raja Pandharicha'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify DeityVideoWatchScreen is pushed
      expect(find.byType(DeityVideoWatchScreen), findsOneWidget);

      // Verify channel info, actions, Up Next
      expect(find.text('Mahesh Kale'), findsWidgets);
      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('Watch on YouTube'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
    });
  });
}
