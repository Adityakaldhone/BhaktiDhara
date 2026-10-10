import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/ganesha_songs_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/ganesha_songs_screen.dart';
import 'package:nitya_aarti/presentation/screens/ganesha_video_watch_screen.dart';
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

  group('Lord Ganesha YouTube Songs Catalog & Screen Flow Tests', () {
    test('kGaneshaSongsCatalog contains all 45 embeddable YouTube songs', () {
      expect(kGaneshaSongsCatalog.length, 45);

      for (final song in kGaneshaSongsCatalog) {
        expect(song.videoId.isNotEmpty, isTrue);
        expect(song.song.isNotEmpty, isTrue);
        expect(song.channel.isNotEmpty, isTrue);
        expect(song.thumbnailUrl, contains('img.youtube.com/vi/${song.videoId}/hqdefault.jpg'));
      }
    });

    test('deityCategoriesProvider for Lord Ganesha contains song and excludes aarti and bhajan', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final categories = container.read(deityCategoriesProvider('Lord Ganesha'));
      expect(categories.contains(BhaktiCategory.aarti), isFalse);
      expect(categories.contains(BhaktiCategory.bhajan), isFalse);
      expect(categories.contains(BhaktiCategory.song), isTrue);
      expect(categories.contains(BhaktiCategory.chalisa), isTrue);
      expect(categories.contains(BhaktiCategory.mantra), isTrue);
      expect(categories.contains(BhaktiCategory.stotra), isTrue);
    });

    testWidgets('Tapping Songs button on Bhakti tab opens GaneshaSongsScreen (YouTube list style)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
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

      // Verify Songs button ('गाणी') is present
      final songsButtons = find.widgetWithText(BhaktiCategoryButton, 'गाणी');
      expect(songsButtons, findsWidgets);

      // Tap Songs button
      await tester.tap(songsButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // GaneshaSongsScreen must be pushed
      expect(find.byType(GaneshaSongsScreen), findsOneWidget);

      // Verify search input field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify category pills are visible
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Bollywood'), findsOneWidget);
      expect(find.text('Aarti'), findsOneWidget);

      // Verify first song card is displayed
      expect(find.text('Deva Shree Ganesha (Agneepath)'), findsOneWidget);
    });

    testWidgets('GaneshaSongsScreen allows searching and selecting a song to open GaneshaVideoWatchScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GaneshaSongsScreen(),
        ),
      );
      await tester.pump();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Vaastav');
      await tester.pump();

      // Verify filtered result
      expect(find.text('Shendur Laal Chadhayo (Vaastav)'), findsOneWidget);

      // Tap on the song card
      await tester.tap(find.text('Shendur Laal Chadhayo (Vaastav)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify GaneshaVideoWatchScreen is pushed
      expect(find.byType(GaneshaVideoWatchScreen), findsOneWidget);

      // Verify YouTube watch page elements: Channel name, action pills, Up Next (No Comments, No Subscribe)
      expect(find.text('T-Series Bollywood Classics'), findsWidgets);
      expect(find.text('Comments'), findsNothing);
      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('Up Next'), findsOneWidget);

      // Verify compliance elements: 'Watch on YouTube' button, 'Favorite', 'Up Next'
      expect(find.text('Watch on YouTube'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);

      // Verify favorite button tap
      final favFinder = find.byIcon(Icons.favorite_border_rounded);
      expect(favFinder, findsOneWidget);
      await tester.tap(favFinder);
      await tester.pump();
      expect(find.text('Favorited'), findsOneWidget);
    });
  });
}
