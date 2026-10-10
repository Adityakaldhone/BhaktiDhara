import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhakti_deity_catalog.dart';
import 'package:nitya_aarti/data/datasources/datta_songs_catalog.dart';
import 'package:nitya_aarti/data/datasources/krishna_songs_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/review_provider.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/datta_songs_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_video_watch_screen.dart';
import 'package:nitya_aarti/presentation/screens/krishna_songs_screen.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/category_button.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/deity_category_bottom_sheet.dart';
import 'package:nitya_aarti/services/review_service.dart';
import 'package:nitya_aarti/services/review_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Lord Krishna & Lord Datta Songs and Category Flow Tests', () {
    test('kKrishnaSongsCatalog has all 100 songs with exact IDs and YouTube videos', () {
      expect(kKrishnaSongsCatalog.length, 100);

      final achyutam = kKrishnaSongsCatalog.firstWhere((s) => s.videoId == '5-Xoh7jKVo8');
      expect(achyutam.song, 'Achyutam Keshavam Krishna Damodaram');

      final radheRadhe = kKrishnaSongsCatalog.firstWhere((s) => s.videoId == 'GsAniOkNTbE');
      expect(radheRadhe.song, 'Radhe Radhe Japa Karo');

      final kunjBihari = kKrishnaSongsCatalog.firstWhere((s) => s.videoId == 'EMO1AT1UQf0');
      expect(kunjBihari.song, 'Aarti Kunj Bihari Ki');
      expect(kunjBihari.category, 'Aarti & Kirtan');

      final shyam = kKrishnaSongsCatalog.firstWhere((s) => s.videoId == 'lxKFe_1QVRA');
      expect(shyam.song, 'Hare Ka Sahara Baba Shyam Hamara');
      expect(shyam.category, 'Khatu Shyam');
    });

    test('kDattaSongsCatalog has all 133 items (100 songs + 24 stotras + 6 mantras + 3 chalisas)', () {
      expect(kDattaSongsCatalog.length, 133);

      // Verify songs
      final pradakshina = kDattaSongsCatalog.firstWhere((s) => s.videoId == '8oQNTAeesGg');
      expect(pradakshina.song, contains('धन्य धन्य हो प्रदक्षिणा'));
      expect(pradakshina.viewsText, '69M views');

      final jagatVandya = kDattaSongsCatalog.firstWhere((s) => s.videoId == '3GrrvUuWrMw');
      expect(jagatVandya.song, contains('जगत वंद्य अवधूत'));

      // Verify stotras
      final stotras = kDattaSongsCatalog.where((s) => s.category == 'Stotra & Kavach').toList();
      expect(stotras.length, 24);
      expect(stotras.any((s) => s.song == 'Shri Datta Stavam (Anasuya Suta)'), isTrue);
      expect(stotras.any((s) => s.song == 'Ghorakashtodharan Stotra'), isTrue);
      expect(stotras.any((s) => s.song == 'Datta Bavani'), isTrue);
      expect(stotras.any((s) => s.song == 'Karunatripadi (Shant Ho Shri Gurudatta)'), isTrue);
      expect(stotras.any((s) => s.song == 'Siddha Mangala Stotram'), isTrue);
      expect(stotras.any((s) => s.song == '52 Shloki Gurucharitra'), isTrue);

      // Verify mantras
      final mantras = kDattaSongsCatalog.where((s) => s.category == 'Mantra & Jap').toList();
      expect(mantras.length, 6);
      expect(mantras.any((s) => s.song == 'Digambara Digambara Shripad Vallabh Digambara'), isTrue);
      expect(mantras.any((s) => s.song == 'Om Dram Dattatreyaya Namah'), isTrue);
      expect(mantras.any((s) => s.song == 'Datta Gayatri Mantra'), isTrue);

      // Verify chalisas
      final chalisas = kDattaSongsCatalog.where((s) => s.category == 'Chalisa').toList();
      expect(chalisas.length, 3);
    });

    test('buildItemsForDeityCategory creates full collections for Lord Krishna and Lord Datta', () {
      final krishna = kBhaktiDeities.firstWhere((d) => d.key == 'Lord Krishna');
      final datta = kBhaktiDeities.firstWhere((d) => d.key == 'Lord Datta');

      // Datta categories
      final dattaStotras = buildItemsForDeityCategory(
        deity: datta,
        category: BhaktiCategory.stotra,
        localeCode: 'mr',
        aartiItems: const [],
      );
      expect(dattaStotras.length, greaterThanOrEqualTo(24));
      expect(dattaStotras.any((it) => it.title.contains('Ghorakashtodharan')), isTrue);

      final dattaMantras = buildItemsForDeityCategory(
        deity: datta,
        category: BhaktiCategory.mantra,
        localeCode: 'mr',
        aartiItems: const [],
      );
      expect(dattaMantras.length, greaterThanOrEqualTo(6));
      expect(dattaMantras.any((it) => it.title.contains('Digambara Digambara')), isTrue);

      final dattaChalisas = buildItemsForDeityCategory(
        deity: datta,
        category: BhaktiCategory.chalisa,
        localeCode: 'mr',
        aartiItems: const [],
      );
      expect(dattaChalisas.length, greaterThanOrEqualTo(3));

      // Krishna categories
      final krishnaAartis = buildItemsForDeityCategory(
        deity: krishna,
        category: BhaktiCategory.aarti,
        localeCode: 'mr',
        aartiItems: const [],
      );
      expect(krishnaAartis.length, greaterThanOrEqualTo(2));
      expect(krishnaAartis.any((it) => it.title.contains('Kunj Bihari') || it.title.contains('कुंजबिहारी')), isTrue);
    });

    testWidgets('Tapping Songs button for Lord Krishna opens KrishnaSongsScreen', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Lord Krishna'),
            selectedDeityIndexProvider.overrideWith((ref) => 0),
            reviewServiceProvider.overrideWithValue(reviewService),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('mr'), Locale('hi'), Locale('en')],
            locale: Locale('mr'),
            home: Scaffold(body: BhajanScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final songButtons = find.widgetWithText(BhaktiCategoryButton, 'गाणी');
      expect(songButtons, findsWidgets);

      await tester.tap(songButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(KrishnaSongsScreen), findsOneWidget);
      expect(find.text('Achyutam Keshavam Krishna Damodaram'), findsOneWidget);
    });

    testWidgets('Tapping Stotra button for Lord Datta opens DeityCategoryBottomSheet with all 24 stotras', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Lord Datta'),
            selectedDeityIndexProvider.overrideWith((ref) => 0),
            reviewServiceProvider.overrideWithValue(reviewService),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('mr'), Locale('hi'), Locale('en')],
            locale: Locale('mr'),
            home: Scaffold(body: BhajanScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final stotraButtons = find.widgetWithText(BhaktiCategoryButton, 'स्तोत्र');
      expect(stotraButtons, findsWidgets);

      await tester.tap(stotraButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DeityCategoryBottomSheet), findsOneWidget);
      expect(find.text('Ghorakashtodharan Stotra'), findsOneWidget);

      // Tap on Ghorakashtodharan Stotra to watch video
      await tester.tap(find.text('Ghorakashtodharan Stotra'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DeityVideoWatchScreen), findsOneWidget);
    });

    testWidgets('Tapping Songs button for Lord Datta opens DattaSongsScreen', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Lord Datta'),
            selectedDeityIndexProvider.overrideWith((ref) => 0),
            reviewServiceProvider.overrideWithValue(reviewService),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('mr'), Locale('hi'), Locale('en')],
            locale: Locale('mr'),
            home: Scaffold(body: BhajanScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final songButtons = find.widgetWithText(BhaktiCategoryButton, 'गाणी');
      expect(songButtons, findsWidgets);

      await tester.tap(songButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DattaSongsScreen), findsOneWidget);
      expect(find.textContaining('धन्य धन्य हो प्रदक्षिणा'), findsOneWidget);
    });
  });
}
