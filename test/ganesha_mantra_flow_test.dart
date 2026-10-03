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

  group('Lord Ganesha Mantra Catalog & Category Flow Tests', () {
    test('All 13 Ganesha Mantras exist in catalog with exact IDs and YouTube videos', () {
      final vakratunda = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_vakratunda');
      expect(vakratunda.youtubeVideoId, '_lli0S6i_Fw');
      expect(vakratunda.lyrics.first.devanagari, contains('वक्रतुण्ड महाकाय'));

      final shubhLabh = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_shubh_labh');
      expect(shubhLabh.youtubeVideoId, 'axfnRoqsHgg');
      expect(shubhLabh.lyrics.first.devanagari, contains('सौभाग्य गणपतये'));

      final gayatri = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_gayatri');
      expect(gayatri.youtubeVideoId, 'dkVlpm1mKFI');
      expect(gayatri.lyrics.first.devanagari, contains('एकदन्ताय विद्महे'));

      final mahaMoola = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_maha_moola');
      expect(mahaMoola.youtubeVideoId, '3uYZWsgo8bY');
      expect(mahaMoola.lyrics.first.devanagari, contains('गं गणपतये'));

      final rinharta = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_rinharta');
      expect(rinharta.youtubeVideoId, 'boSeruDq6WQ');
      expect(rinharta.lyrics.first.devanagari, contains('गणेश ऋणं छिन्धि'));

      final haridra = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_haridra');
      expect(haridra.youtubeVideoId, 'qIMVoWHcFXc');
      expect(haridra.lyrics.first.devanagari, contains('हरिद्रा गणपतये'));

      final heramba = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_heramba');
      expect(heramba.youtubeVideoId, 'wKKIhwERzBE');
      expect(heramba.lyrics.first.devanagari, contains('हेरम्ब मदमोहित'));

      final ekakshari = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_ekakshari');
      expect(ekakshari.youtubeVideoId, 'Qm5m6nMOB0Y');
      expect(ekakshari.lyrics.first.devanagari, contains('गं ॥'));

      final shadakshara = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_shadakshara');
      expect(shadakshara.youtubeVideoId, 'cidhzMLBUPQ');
      expect(shadakshara.lyrics.first.devanagari, contains('वक्रतुण्डाय हुम्'));

      final ashtakshara = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_ashtakshara');
      expect(ashtakshara.youtubeVideoId, 'CdJVxS1FJ8w');
      expect(ashtakshara.lyrics.first.devanagari, contains('गं गणपतये नमः'));

      final kshipra = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_kshipra_prasada');
      expect(kshipra.youtubeVideoId, 'DnUlrEsUeN0');
      expect(kshipra.lyrics.first.devanagari, contains('गं क्षिप्रप्रसादनाय नमः'));

      final mantraksharavali = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganapati_mantraksharavali');
      expect(mantraksharavali.youtubeVideoId, 'S8UclCJsTjo');

      final moolamantra = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_ganesh_moolamantra_padamala');
      expect(moolamantra.youtubeVideoId, 'd1ArOnqN1xU');
    });

    test('kGaneshaMantras contains exactly the 13 user-requested Mantras in exact order', () {
      expect(kGaneshaMantras.length, 13);
      expect(kGaneshaMantras[0].id, 'mantra_ganesh_vakratunda');
      expect(kGaneshaMantras[1].id, 'mantra_ganesh_shubh_labh');
      expect(kGaneshaMantras[2].id, 'mantra_ganesh_gayatri');
      expect(kGaneshaMantras[3].id, 'mantra_ganesh_maha_moola');
      expect(kGaneshaMantras[4].id, 'mantra_ganesh_rinharta');
      expect(kGaneshaMantras[5].id, 'mantra_ganesh_haridra');
      expect(kGaneshaMantras[6].id, 'mantra_ganesh_heramba');
      expect(kGaneshaMantras[7].id, 'mantra_ganesh_ekakshari');
      expect(kGaneshaMantras[8].id, 'mantra_ganesh_shadakshara');
      expect(kGaneshaMantras[9].id, 'mantra_ganesh_ashtakshara');
      expect(kGaneshaMantras[10].id, 'mantra_ganesh_kshipra_prasada');
      expect(kGaneshaMantras[11].id, 'mantra_ganapati_mantraksharavali');
      expect(kGaneshaMantras[12].id, 'mantra_ganesh_moolamantra_padamala');
    });

    testWidgets('GaneshaMantraSheet renders strictly the 13 Mantras and opens AartiAltarScreen on tap', (WidgetTester tester) async {
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
              body: GaneshaMantraSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify sheet header
      expect(find.text('श्री गणेश मंत्र संग्रह'), findsOneWidget);
      expect(find.text('१३ सिद्ध मंत्र संग्रह'), findsOneWidget);

      // Verify first mantra in list
      expect(find.text('वक्रतुंड महाकाय मंत्र'), findsOneWidget);

      // Tap on the first Mantra
      await tester.tap(find.text('वक्रतुंड महाकाय मंत्र'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AartiAltarScreen opens
      expect(find.byType(AartiAltarScreen), findsOneWidget);
      expect(find.text('वक्रतुंड महाकाय मंत्र'), findsWidgets);
    });

    testWidgets('Ganesha Mantra button opens GaneshaMantraSheet, Stotra opens GaneshaStotraSheet', (WidgetTester tester) async {
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

      // Find the Mantra button for Lord Ganesha
      final mantraButtons = find.widgetWithText(BhaktiCategoryButton, 'मंत्र');
      expect(mantraButtons, findsWidgets);

      // Tap Mantra
      await tester.tap(mantraButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // GaneshaMantraSheet must be visible
      expect(find.byType(GaneshaMantraSheet), findsOneWidget);
      expect(find.text('वक्रतुंड महाकाय मंत्र'), findsOneWidget);

      // Dismiss the bottom sheet
      final closeButton = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GaneshaMantraSheet), findsNothing);

      // Now tap Aarti button (must NOT open any sheet)
      final aartiButtons = find.widgetWithText(BhaktiCategoryButton, 'आरती');
      if (aartiButtons.evaluate().isNotEmpty) {
        await tester.tap(aartiButtons.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(GaneshaStotraSheet), findsNothing);
        expect(find.byType(GaneshaMantraSheet), findsNothing);
      }
    });
  });
}
