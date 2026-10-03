import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhajan_catalog.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/review_provider.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/category_button.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/ganesha_stotra_sheet.dart';
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

  group('Lord Ganesha Stotra Catalog & Category Flow Tests', () {
    test('All 4 Ganesha Stotras exist in catalog with exact IDs and YouTube videos', () {
      final ashtakam = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_gananayak_ashtakam');
      expect(ashtakam.titleHi, 'श्री गणनायकाष्टकम्');
      expect(ashtakam.titleMr, 'श्री गणनायकाष्टकम्');
      expect(ashtakam.youtubeVideoId, 'xdiCqgp-Llw');
      expect(ashtakam.deity, 'Lord Ganesha');
      expect(ashtakam.lyrics.length, 9);
      expect(ashtakam.lyrics.first.devanagari, contains('एकदन्तं महाकायं'));

      final stavah = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_ganapati_stavah');
      expect(stavah.titleHi, 'श्री गणपति स्तवः');
      expect(stavah.titleMr, 'श्री गणपति स्तवः');
      expect(stavah.youtubeVideoId, 'ryIk3Rc2Qso');
      expect(stavah.deity, 'Lord Ganesha');
      expect(stavah.lyrics.length, 13);
      expect(stavah.lyrics.first.devanagari, contains('अजं निर्विकल्पं'));

      final divyadurg = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_ganesh_divyadurg');
      expect(divyadurg.titleHi, 'श्री गणेश दिव्यदुर्ग स्तोत्रम्');
      expect(divyadurg.titleMr, 'श्री गणेश दिव्यदुर्ग स्तोत्रम्');
      expect(divyadurg.youtubeVideoId, 'cuSeY0LRD8Q');
      expect(divyadurg.deity, 'Lord Ganesha');
      expect(divyadurg.lyrics.length, 15);
      expect(divyadurg.lyrics.first.devanagari, contains('वद शिव महानाथ'));

      final pancharatnam = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_ganesh_pancharatnam');
      expect(pancharatnam.titleHi, 'श्री गणेश पञ्चरत्नम्');
      expect(pancharatnam.youtubeVideoId, 'kJVdjMaObtA');
      expect(pancharatnam.deity, 'Lord Ganesha');
      expect(pancharatnam.lyrics.length, 6);
      expect(pancharatnam.lyrics.first.devanagari, contains('मुदा करात्तमोदकं'));
    });

    test('kGaneshaStotras contains exactly the 4 user-requested Stotras in exact order', () {
      expect(kGaneshaStotras.length, 4);
      expect(kGaneshaStotras[0].id, 'stotra_gananayak_ashtakam');
      expect(kGaneshaStotras[1].id, 'stotra_ganapati_stavah');
      expect(kGaneshaStotras[2].id, 'stotra_ganesh_divyadurg');
      expect(kGaneshaStotras[3].id, 'stotra_ganesh_pancharatnam');
    });

    testWidgets('GaneshaStotraSheet renders strictly the 4 Stotras and opens AartiAltarScreen on tap', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            reviewServiceProvider.overrideWithValue(reviewService),
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
              body: GaneshaStotraSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify sheet header
      expect(find.text('श्री गणेश स्तोत्र संग्रह'), findsOneWidget);
      expect(find.text('४ पवित्र स्तोत्रे'), findsOneWidget);

      // Verify strictly the 4 Stotras are listed
      expect(find.text('श्री गणनायकाष्टकम्'), findsOneWidget);
      expect(find.text('श्री गणपति स्तवः'), findsOneWidget);
      expect(find.text('श्री गणेश दिव्यदुर्ग स्तोत्रम्'), findsOneWidget);
      expect(find.text('श्री गणेश पंचरत्न स्तोत्र'), findsOneWidget);

      // Verify verse preview snippets
      expect(find.textContaining('एकदन्तं महाकायं'), findsOneWidget);
      expect(find.textContaining('अजं निर्विकल्पं'), findsOneWidget);

      // Tap on the first Stotra (श्री गणनायकाष्टकम्)
      await tester.tap(find.text('श्री गणनायकाष्टकम्'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AartiAltarScreen opens
      expect(find.byType(AartiAltarScreen), findsOneWidget);
      expect(find.text('श्री गणनायकाष्टकम्'), findsWidgets);
    });

    testWidgets('Only Stotra button triggers sheet; other category buttons do not open sheets', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            reviewServiceProvider.overrideWithValue(reviewService),
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

      // Find Aarti button and tap it
      final aartiButton = find.widgetWithText(BhaktiCategoryButton, 'आरती');
      if (aartiButton.evaluate().isNotEmpty) {
        await tester.tap(aartiButton.first);
        await tester.pump(const Duration(milliseconds: 200));

        // Sheet should NOT open for Aarti
        expect(find.byType(GaneshaStotraSheet), findsNothing);
      }

      // Tap Stotra button
      final stotraButton = find.widgetWithText(BhaktiCategoryButton, 'स्तोत्र');
      expect(stotraButton, findsWidgets);

      await tester.tap(stotraButton.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sheet opens ONLY for Stotra
      expect(find.byType(GaneshaStotraSheet), findsOneWidget);
    });
  });
}
