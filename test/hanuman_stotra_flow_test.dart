import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhajan_catalog.dart';
import 'package:nitya_aarti/data/datasources/hanuman_stotras_catalog.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/review_provider.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/category_button.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/hanuman_stotra_sheet.dart';
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

  group('Lord Hanuman 27 Stotras Catalog & Category Flow Tests', () {
    test('All 27 Hanuman Stotras exist in catalog with exact IDs and YouTube videos', () {
      final expected = [
        ('stotra_hanuman_chalisa_tulsidas', 'AETFvQonfV8', 'श्रीगुरु चरन सरोज'),
        ('stotra_hanuman_bajrang_baan', 'h1lT6cxwsPw', 'निश्चय प्रेम प्रतीति'),
        ('stotra_sankat_mochan_ashtak', 'HH_a6aRO1TE', 'बाल समय रबि भक्षि लियो'),
        ('aarti_hanuman_lala_ki', 'r7GJ8GoGSD8', 'आरती कीजै हनुमान लला'),
        ('stotra_maruti_bhimrupi', 'XIOhPTccsJQ', 'भीमरूपी महारुद्रा'),
        ('stotra_anjaneya_dandakam', 'FRsoO7WM910', 'श्री आञ्जनेयं'),
        ('stotra_hanuman_dwadash_nama_stotram', 'OS_nmFGtNN4', 'श्रीआञ्जनेयद्वादशनाम'),
        ('stotra_hanuman_manojavam', '2HcOLLFSR0M', 'मनोजवं मारुततुल्यवेग'),
        ('stotra_panchmukhi_kavach_sudarshana', '3QKaQ4tGf7Y', 'पञ्चवक्त्रं महाभीमं'),
        ('stotra_ekadashmukhi_hanuman_kavach', 'xhcAfF_gG0s', 'शैवानि गाणपत्यानि'),
        ('stotra_hanuman_ashtottara_shatanamavali', 's1sSHoaW9u4', 'ॐ आञ्जनेयाय नमः'),
        ('stotra_anjaneya_mangalashtakam', 'Skn7Zorioro', 'कपिश्रेष्ठाय शूराय'),
        ('stotra_hanuman_bahuk', 'EWCkUAY-0OU', 'सिंधु तरन, सिय-सोच'),
        ('stotra_hanuman_vadvanal', 'jeVjfNQ_pAI', 'श्रीहनुमद्वडवानलस्तोत्रमन्त्रस्य'),
        ('stotra_hanuman_gayatri_mantra', 'Jp1lM2JO4aQ', 'ॐ आञ्जनेयाय विद्महे'),
        ('stotra_hanuman_mool_mantra', 'ntUuengIr1A', 'ॐ हं हनुमते नमः'),
        ('stotra_hanumat_pancharatnam_shankara', 'uwHnBGn4I90', 'वीताखिलविषयेच्छं'),
        ('stotra_hanuman_stavan', '90Jg2ZI_RLo', 'प्रनवउँ पवनकुमार'),
        ('stotra_hanuman_sathika', 'P8VH9E-t1W0', 'जय जय जय हनुमान अडंग'),
        ('stotra_hanuman_raksha_stotram', 'Aw7bSSUSf1Q', 'वामे करे वैरिभिदं'),
        ('stotra_hanuman_bhujanga_prayata', '4dUR7omDe5M', 'मनोजवं मारुततुल्यवेग'),
        ('stotra_hanuman_tandav', 'AjCLVm6gKQc', 'वन्दे सिन्दूरवर्णाभं'),
        ('stotra_langoolastra_shatrunjaya', 'I7b_kwU8uR4', 'लोकाभीरामं रणरङ्गधीर'),
        ('stotra_apaduddharaka_hanumat', 'j23clf3Im7E', 'आपन्नाखिललोकार्तिहार'),
        ('stotra_ekamukhi_hanuman_kavach', 'PissO9bGzDY', 'मनोजवं मारुततुल्यवेग'),
        ('aarti_maruti_satrane_uddane', 'Bfk6nx8Rg2Y', 'सत्राणे उड्डाणे'),
        ('stotra_hanumat_stotram_vibhishana', 'bvzxi0SpvMc', 'नमो हनुमते तुभ्यं'),
      ];

      expect(kHanumanStotrasCatalog.length, 27);
      expect(kHanumanStotras.length, 27);

      for (int i = 0; i < expected.length; i++) {
        final (id, expectedVid, expectedDevanagariSub) = expected[i];
        final item = kBhajanCatalog.firstWhere(
          (x) => x.id == id,
          orElse: () => throw Exception('Could not find $id in kBhajanCatalog'),
        );
        expect(item.youtubeVideoId, expectedVid, reason: 'Video ID mismatch for $id');
        expect(
          item.lyrics.any((s) => s.devanagari.contains(expectedDevanagariSub)),
          isTrue,
          reason: 'Lyrics missing $expectedDevanagariSub for $id',
        );
        expect(item.lyrics.first.transliteration.isNotEmpty, isTrue);
      }
    });

    testWidgets('HanumanStotraSheet renders strictly the 27 Stotras and opens AartiAltarScreen on tap', (WidgetTester tester) async {
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
              body: HanumanStotraSheet(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify sheet header
      expect(find.text('श्री हनुमान स्तोत्र संग्रह'), findsOneWidget);
      expect(find.text('२७ पवित्र स्तोत्रे'), findsOneWidget);

      // Verify first stotra in list
      expect(find.text('श्री हनुमान चालीसा'), findsOneWidget);

      // Tap on the first Stotra
      await tester.tap(find.text('श्री हनुमान चालीसा'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AartiAltarScreen opens
      expect(find.byType(AartiAltarScreen), findsOneWidget);
      expect(find.text('श्री हनुमान चालीसा'), findsWidgets);
    });

    testWidgets('Lord Hanuman Stotra category button opens HanumanStotraSheet', (WidgetTester tester) async {
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

      // Find the Stotra button for Lord Hanuman
      final stotraButtons = find.widgetWithText(BhaktiCategoryButton, 'स्तोत्र');
      expect(stotraButtons, findsWidgets);

      // Tap Stotra
      await tester.tap(stotraButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // HanumanStotraSheet must be visible
      expect(find.byType(HanumanStotraSheet), findsOneWidget);
      expect(find.text('श्री हनुमान स्तोत्र संग्रह'), findsOneWidget);
      expect(find.text('२७ पवित्र स्तोत्रे'), findsOneWidget);

      // Dismiss the bottom sheet
      final closeButton = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HanumanStotraSheet), findsNothing);
    });
  });
}
