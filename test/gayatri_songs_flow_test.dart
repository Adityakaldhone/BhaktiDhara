import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/gayatri_songs_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_video_watch_screen.dart';
import 'package:nitya_aarti/presentation/screens/gayatri_songs_screen.dart';
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

  group('Goddess Gayatri YouTube Songs Catalog & Flow Tests', () {
    test('kGayatriSongsCatalog contains all 53 embeddable YouTube songs', () {
      expect(kGayatriSongsCatalog.length, 53);

      for (final song in kGayatriSongsCatalog) {
        expect(song.videoId.isNotEmpty, isTrue);
        expect(song.song.isNotEmpty, isTrue);
        expect(song.channel.isNotEmpty, isTrue);
        expect(song.thumbnailUrl, contains('img.youtube.com/vi/${song.videoId}/hqdefault.jpg'));
      }
    });

    test('deityCategoriesProvider for Goddess Gayatri contains song and core categories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final categories = container.read(deityCategoriesProvider('Goddess Gayatri'));
      expect(categories.contains(BhaktiCategory.song), isTrue);
      expect(categories.contains(BhaktiCategory.aarti), isTrue);
      expect(categories.contains(BhaktiCategory.chalisa), isTrue);
      expect(categories.contains(BhaktiCategory.mantra), isTrue);
      expect(categories.contains(BhaktiCategory.stotra), isTrue);
    });

    testWidgets('Tapping Songs button on Bhakti tab for Goddess Gayatri opens GayatriSongsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Goddess Gayatri'),
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

      // Verify Songs button ('गाणी') is present for Goddess Gayatri
      final songsButtons = find.widgetWithText(BhaktiCategoryButton, 'गाणी');
      expect(songsButtons, findsWidgets);

      // Tap Songs button
      await tester.tap(songsButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // GayatriSongsScreen must be pushed
      expect(find.byType(GayatriSongsScreen), findsOneWidget);

      // Verify search input field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify category pills are visible
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Gayatri Mantra & Jaap'), findsOneWidget);

      // Verify rank 1 song card is displayed
      expect(find.text('Gayatri Mantra (Om Bhur Bhuva Swaha)'), findsOneWidget);
    });

    testWidgets('GayatriSongsScreen allows searching and selecting a song to open DeityVideoWatchScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GayatriSongsScreen(),
        ),
      );
      await tester.pump();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Shatak Path');
      await tester.pump();

      // Verify filtered result
      expect(find.text('Gayatri Shatak Path (Gujarati)'), findsOneWidget);

      // Tap on the song card
      await tester.tap(find.text('Gayatri Shatak Path (Gujarati)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify DeityVideoWatchScreen is pushed
      expect(find.byType(DeityVideoWatchScreen), findsOneWidget);

      // Verify channel info, actions, Up Next
      expect(find.text('Avani Prajapati Digital'), findsWidgets);
      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('Watch on YouTube'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
    });
  });
}
