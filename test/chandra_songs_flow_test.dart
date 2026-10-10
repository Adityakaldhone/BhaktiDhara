import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/chandra_songs_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/chandra_songs_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_video_watch_screen.dart';
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

  group('Chandra Dev YouTube Songs Catalog & Flow Tests', () {
    test('kChandraSongsCatalog contains all 35 embeddable YouTube songs', () {
      expect(kChandraSongsCatalog.length, 35);

      for (final song in kChandraSongsCatalog) {
        expect(song.videoId.isNotEmpty, isTrue);
        expect(song.song.isNotEmpty, isTrue);
        expect(song.channel.isNotEmpty, isTrue);
        expect(song.thumbnailUrl, contains('img.youtube.com/vi/${song.videoId}/hqdefault.jpg'));
      }
    });

    test('deityCategoriesProvider for Chandra Dev contains song and aarti categories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final categories = container.read(deityCategoriesProvider('Chandra Dev'));
      expect(categories.contains(BhaktiCategory.song), isTrue);
      expect(categories.contains(BhaktiCategory.aarti), isTrue);
    });

    testWidgets('Tapping Songs button on Bhakti tab for Chandra Dev opens ChandraSongsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Chandra Dev'),
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

      // Verify Songs button ('गाणी') is present for Chandra Dev
      final songsButtons = find.widgetWithText(BhaktiCategoryButton, 'गाणी');
      expect(songsButtons, findsWidgets);

      // Tap Songs button
      await tester.tap(songsButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ChandraSongsScreen must be pushed
      expect(find.byType(ChandraSongsScreen), findsOneWidget);

      // Verify search input field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify category pills are visible
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Mantra & Jaap'), findsOneWidget);

      // Verify rank 1 song card is displayed
      expect(find.text('Om Som Somaya Namah (Chandra Beej Mantra)'), findsOneWidget);
    });

    testWidgets('ChandraSongsScreen allows searching and selecting a song to open DeityVideoWatchScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChandraSongsScreen(),
        ),
      );
      await tester.pump();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Chandra Gayatri');
      await tester.pump();

      // Verify filtered result
      expect(find.text('Chandra Gayatri Mantra'), findsOneWidget);

      // Tap on the song card
      await tester.tap(find.text('Chandra Gayatri Mantra'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify DeityVideoWatchScreen is pushed
      expect(find.byType(DeityVideoWatchScreen), findsOneWidget);

      // Verify channel info, actions, Up Next
      expect(find.text('Rajshri Soul'), findsWidgets);
      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('Watch on YouTube'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
    });
  });
}
