import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhakti_deity_catalog.dart';
import 'package:nitya_aarti/domain/entities/bhakti_deity.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/bhakti_darshan_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_video_watch_screen.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/category_button.dart';
import 'package:nitya_aarti/presentation/widgets/bhakti/deity_category_bottom_sheet.dart';
import 'package:nitya_aarti/presentation/providers/review_provider.dart';
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

  group('DeityCategoryBottomSheet Catalog & Flow Tests', () {
    test('buildItemsForDeityCategory extracts full collections of Stotras, Mantras, Aartis for deities', () {
      final durga = kBhaktiDeities.firstWhere((d) => d.key == 'Goddess Durga');
      final gayatri = kBhaktiDeities.firstWhere((d) => d.key == 'Goddess Gayatri');
      final balumama = kBhaktiDeities.firstWhere((d) => d.key == 'Sant Balumama');
      final shiva = kBhaktiDeities.firstWhere((d) => d.key == 'Lord Shiva');

      // Durga collections
      final durgaStotras = buildItemsForDeityCategory(
        deity: durga,
        category: BhaktiCategory.stotra,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(durgaStotras.length, greaterThanOrEqualTo(25));
      expect(durgaStotras.any((it) => it.title.contains('Mahishasura Mardini')), isTrue);

      final durgaMantras = buildItemsForDeityCategory(
        deity: durga,
        category: BhaktiCategory.mantra,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(durgaMantras.length, greaterThanOrEqualTo(15));
      expect(durgaMantras.any((it) => it.title.contains('Navarna Mantra')), isTrue);

      // Gayatri collections
      final gayatriStotras = buildItemsForDeityCategory(
        deity: gayatri,
        category: BhaktiCategory.stotra,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(gayatriStotras.length, greaterThanOrEqualTo(12));
      expect(gayatriStotras.any((it) => it.title.contains('Gayatri Shatak Path')), isTrue);

      final gayatriMantras = buildItemsForDeityCategory(
        deity: gayatri,
        category: BhaktiCategory.mantra,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(gayatriMantras.length, greaterThanOrEqualTo(3));
      expect(gayatriMantras.any((it) => it.title.contains('Gayatri Mantra')), isTrue);

      // Balumama collections
      final balumamaAartis = buildItemsForDeityCategory(
        deity: balumama,
        category: BhaktiCategory.aarti,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(balumamaAartis.length, greaterThanOrEqualTo(7));
      expect(balumamaAartis.any((it) => it.title.contains('Jay Balumama')), isTrue);

      final balumamaMantras = buildItemsForDeityCategory(
        deity: balumama,
        category: BhaktiCategory.mantra,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(balumamaMantras.length, greaterThanOrEqualTo(10));
      expect(balumamaMantras.any((it) => it.title.contains('Balumama Mantra')), isTrue);

      // Shiva collections
      final shivaStotras = buildItemsForDeityCategory(
        deity: shiva,
        category: BhaktiCategory.stotra,
        aartiItems: const [],
        localeCode: 'mr',
      );
      expect(shivaStotras.length, greaterThanOrEqualTo(20));
      expect(shivaStotras.any((it) => it.title.contains('Shiv Tandav')), isTrue);
    });

    testWidgets('Tapping Stotra button for Goddess Durga opens DeityCategoryBottomSheet with all stotras', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Goddess Durga'),
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

      // Locate Stotra button ('स्तोत्र')
      final stotraButtons = find.widgetWithText(BhaktiCategoryButton, 'स्तोत्र');
      expect(stotraButtons, findsWidgets);

      // Tap Stotra button
      await tester.tap(stotraButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // DeityCategoryBottomSheet must be displayed
      expect(find.byType(DeityCategoryBottomSheet), findsOneWidget);

      // Verify title and stotra items in the list
      expect(find.text('श्री दुर्गा माता स्तोत्र संग्रह'), findsOneWidget);
      expect(find.text('Mahishasura Mardini Stotram (Aigiri Nandini)'), findsOneWidget);

      // Tap the first stotra item card
      await tester.tap(find.text('Mahishasura Mardini Stotram (Aigiri Nandini)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Video watch screen opens for the selected stotra
      expect(find.byType(DeityVideoWatchScreen), findsOneWidget);
    });

    testWidgets('Tapping Aarti button for Sant Balumama opens DeityCategoryBottomSheet with all aartis', (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      final reviewStorage = ReviewStorageService(prefs);
      final reviewService = ReviewService(reviewStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            pinnedDeityKeyProvider.overrideWith((ref) => 'Sant Balumama'),
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

      // Locate Aarti button ('आरती')
      final aartiButtons = find.widgetWithText(BhaktiCategoryButton, 'आरती');
      expect(aartiButtons, findsWidgets);

      // Tap Aarti button
      await tester.tap(aartiButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // DeityCategoryBottomSheet must be displayed
      expect(find.byType(DeityCategoryBottomSheet), findsOneWidget);

      // Verify Balumama aarti title and items
      expect(find.text('श्री संत बाळूमामा आरती संग्रह'), findsOneWidget);
      expect(find.text('Jaydev Jaydev Jay Balumama (Adamapur temple aarti)'), findsOneWidget);
    });
  });
}
