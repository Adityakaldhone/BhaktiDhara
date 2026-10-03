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
import 'package:nitya_aarti/presentation/widgets/bhakti/ganesha_chalisa_sheet.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/ganesha_mantra_sheet.dart';
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

  group('Lord Ganesha Chalisa Catalog & Category Flow Tests', () {
    test('Ganesha Chalisa exists in catalog with exact ID and YouTube video', () {
      final chalisa = kBhajanCatalog.firstWhere((i) => i.id == 'chalisa_ganesh');
      expect(chalisa.titleHi, 'श्री गणेश चालीसा');
      expect(chalisa.titleMr, 'श्री गणेश चालीसा');
      expect(chalisa.youtubeVideoId, 'WyHFSjN0miU');
      expect(chalisa.deity, 'Lord Ganesha');
      expect(chalisa.lyrics.isNotEmpty, isTrue);
      expect(chalisa.lyrics.first.devanagari, contains('जय गणपति सदगुण सदन'));
      expect(chalisa.lyrics.last.devanagari, contains('मंगल मूर्ती गणेश'));
    });

    test('kGaneshaChalisas contains exactly the user-requested Ganesha Chalisa', () {
      expect(kGaneshaChalisas.length, 1);
      expect(kGaneshaChalisas[0].id, 'chalisa_ganesh');
    });

    testWidgets('GaneshaChalisaSheet renders the Chalisa and opens AartiAltarScreen on tap', (WidgetTester tester) async {
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
              body: GaneshaChalisaSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify sheet header
      expect(find.text('श्री गणेश चालीसा'), findsWidgets);
      expect(find.text('पावन चालीसा पाठ'), findsOneWidget);

      // Verify verse preview snippet
      expect(find.textContaining('जय गणपति सदगुण सदन'), findsOneWidget);

      // Tap on Chalisa card
      await tester.tap(find.widgetWithText(InkWell, 'श्री गणेश चालीसा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AartiAltarScreen opens
      expect(find.byType(AartiAltarScreen), findsOneWidget);
    });

    testWidgets('Ganesha Chalisa button opens GaneshaChalisaSheet; Aarti does not', (WidgetTester tester) async {
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
      await tester.pump(const Duration(milliseconds: 300));

      // Find the Chalisa button for Lord Ganesha
      final chalisaButtons = find.widgetWithText(BhaktiCategoryButton, 'चालीसा');
      expect(chalisaButtons, findsWidgets);

      // Tap Chalisa button
      await tester.tap(chalisaButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // GaneshaChalisaSheet must be visible
      expect(find.byType(GaneshaChalisaSheet), findsOneWidget);

      // Dismiss the bottom sheet
      final closeButton = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GaneshaChalisaSheet), findsNothing);

      // Tap Aarti button (must NOT open any sheet)
      final aartiButtons = find.widgetWithText(BhaktiCategoryButton, 'आरती');
      if (aartiButtons.evaluate().isNotEmpty) {
        await tester.tap(aartiButtons.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(GaneshaChalisaSheet), findsNothing);
        expect(find.byType(GaneshaStotraSheet), findsNothing);
        expect(find.byType(GaneshaMantraSheet), findsNothing);
      }
    });
  });
}
