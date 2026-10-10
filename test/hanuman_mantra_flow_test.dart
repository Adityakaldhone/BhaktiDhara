import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhajan_catalog.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/review_provider.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/category_button.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/hanuman_mantra_sheet.dart';
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

  group('Lord Hanuman Mantra Catalog & Category Flow Tests', () {
    test('All 11 Hanuman Mantras exist in catalog with exact IDs and YouTube videos', () {
      final beej = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_hanuman_beej');
      expect(beej.youtubeVideoId, 'j1afyq4EM9A');
      expect(beej.lyrics.first.devanagari, contains('ॐ हं हनुमते नमः'));

      final moola = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_hanuman_moola');
      expect(moola.youtubeVideoId, 'BYDOl5Sm-HE');
      expect(moola.lyrics.first.devanagari, contains('ॐ नमो हनुमते रुद्रावताराय'));

      final gayatri = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_hanuman_gayatri');
      expect(gayatri.youtubeVideoId, '6DH_6o6c6vE');
      expect(gayatri.lyrics.first.devanagari, contains('ॐ आञ्जनेयाय विद्महे'));

      final courage = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_hanuman_courage_strength');
      expect(courage.youtubeVideoId, '2HcOLLFSR0M');
      expect(courage.lyrics.first.devanagari, contains('मनोजवम मारुततुल्यवेगम'));

      final kavach = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_panchmukhi_hanuman_kavach');
      expect(kavach.youtubeVideoId, 'Nb6RMSvcHXA');
      expect(kavach.lyrics.first.devanagari, contains('पञ्चमुखि हनुमते नमः'));

      final dwadash = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_aanjaney_dwadash_namah');
      expect(dwadash.youtubeVideoId, 'DyZgk82iC1g');
      expect(dwadash.lyrics.first.devanagari, contains('हनुमानञ्जनासूनुः वायुपुत्रो'));

      final mahabal = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_mahabal_hanumat_stuti');
      expect(mahabal.youtubeVideoId, 'X_90JlTmm94');
      expect(mahabal.lyrics.first.devanagari, contains('ॐ मंगलकारकं संकटनाशं हनुमते नमः'));

      final navgraha = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_navgraha_shanti_hanuman');
      expect(navgraha.youtubeVideoId, 'KPomNPdISV0');
      expect(navgraha.lyrics.first.devanagari, contains('अनिर्वेदः श्रियो मूलं'));

      final smaran = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_hanuman_smaran');
      expect(smaran.youtubeVideoId, 'nkTUq4AxadQ');
      expect(smaran.lyrics.first.devanagari, contains('प्रातः स्मरामि हनुमन्तमनन्तवीर्यं'));

      final pancharatna = kBhajanCatalog.firstWhere((i) => i.id == 'stotra_hanuman_pancharatna');
      expect(pancharatna.youtubeVideoId, 'Q5_JXXCIlzg');
      expect(pancharatna.lyrics.first.devanagari, contains('वीताखिल-विषयेच्छं'));

      final vadavanala = kBhajanCatalog.firstWhere((i) => i.id == 'mantra_hanuman_vadavanala');
      expect(vadavanala.youtubeVideoId, 'XLMTbMxJ2Os');
      expect(vadavanala.lyrics.first.devanagari, contains('हनुमद् वडवानल-स्तोत्र जपमहं करिष्ये'));
    });

    test('kHanumanMantras contains exactly the 11 user-requested Mantras in exact order', () {
      expect(kHanumanMantras.length, 11);
      expect(kHanumanMantras[0].id, 'mantra_hanuman_beej');
      expect(kHanumanMantras[1].id, 'mantra_hanuman_moola');
      expect(kHanumanMantras[2].id, 'mantra_hanuman_gayatri');
      expect(kHanumanMantras[3].id, 'mantra_hanuman_courage_strength');
      expect(kHanumanMantras[4].id, 'mantra_panchmukhi_hanuman_kavach');
      expect(kHanumanMantras[5].id, 'stotra_aanjaney_dwadash_namah');
      expect(kHanumanMantras[6].id, 'stotra_mahabal_hanumat_stuti');
      expect(kHanumanMantras[7].id, 'mantra_navgraha_shanti_hanuman');
      expect(kHanumanMantras[8].id, 'mantra_hanuman_smaran');
      expect(kHanumanMantras[9].id, 'stotra_hanuman_pancharatna');
      expect(kHanumanMantras[10].id, 'mantra_hanuman_vadavanala');
    });

    testWidgets('HanumanMantraSheet renders strictly the 11 Mantras and opens AartiAltarScreen on tap', (WidgetTester tester) async {
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
              body: HanumanMantraSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify sheet header
      expect(find.text('श्री हनुमान मंत्र संग्रह'), findsOneWidget);
      expect(find.text('११ सिद्ध मंत्र संग्रह'), findsOneWidget);

      // Verify first mantra in list
      expect(find.text('मूळ बीज मंत्र'), findsOneWidget);

      // Tap on the first Mantra
      await tester.tap(find.text('मूळ बीज मंत्र'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AartiAltarScreen opens
      expect(find.byType(AartiAltarScreen), findsOneWidget);
      expect(find.text('मूळ बीज मंत्र'), findsWidgets);
    });

    testWidgets('Hanuman Mantra button opens HanumanMantraSheet', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      // Overriding pinnedDeityKeyProvider with 'Lord Hanuman' to focus on Lord Hanuman
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            reviewServiceProvider.overrideWithValue(reviewService),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Lord Hanuman'),
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

      // Find the Mantra button for Lord Hanuman
      final mantraButtons = find.widgetWithText(BhaktiCategoryButton, 'मंत्र');
      expect(mantraButtons, findsWidgets);

      // Tap Mantra
      await tester.tap(mantraButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // HanumanMantraSheet must be visible
      expect(find.byType(HanumanMantraSheet), findsOneWidget);
      expect(find.text('श्री हनुमान मंत्र संग्रह'), findsOneWidget);
      expect(find.text('मूळ बीज मंत्र'), findsOneWidget);

      // Dismiss the bottom sheet
      final closeButton = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HanumanMantraSheet), findsNothing);
    });
  });
}
