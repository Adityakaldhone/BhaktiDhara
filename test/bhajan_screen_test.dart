import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhajan_catalog.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/presentation/screens/bhajan_screen.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Bhajan Tab & Screen Unit & Widget Tests', () {
    test('kBhajanCatalog contains diverse Hindu Bhajans and Kirtans with valid metadata', () {
      expect(kBhajanCatalog.isNotEmpty, isTrue);
      expect(kBhajanCatalog.length, greaterThanOrEqualTo(10));

      final deities = kBhajanCatalog.map((b) => b.deity).toSet();
      expect(deities.contains('Lord Krishna'), isTrue);
      expect(deities.contains('Lord Rama'), isTrue);
      expect(deities.contains('Lord Shiva'), isTrue);
      expect(deities.contains('Lord Vitthal'), isTrue);
      expect(deities.contains('Goddess Durga'), isTrue);
      expect(deities.contains('Lord Ganesha'), isTrue);

      for (final bhajan in kBhajanCatalog) {
        expect(bhajan.id.isNotEmpty, isTrue);
        expect(bhajan.title.isNotEmpty, isTrue);
        expect(bhajan.titleMr.isNotEmpty, isTrue);
        expect(bhajan.titleHi.isNotEmpty, isTrue);
        expect(bhajan.lyrics.isNotEmpty, isTrue);
        expect(bhajan.singer.isNotEmpty, isTrue);
        expect(bhajan.youtubeVideoId.isNotEmpty, isTrue);
      }
    });

    testWidgets('Dashboard navbar switches to Bhajan tab on tap', (WidgetTester tester) async {
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
            home: MandirDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Bhajan nav icon
      expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);

      // Tap Bhajan tab
      await tester.tap(find.byIcon(Icons.library_music_rounded));
      await tester.pumpAndSettle();

      // Verify BhajanScreen is active
      expect(find.byType(BhajanScreen), findsOneWidget);
      expect(find.text('भजन आणि कीर्तन'), findsOneWidget);

      // Verify Bhajan cards render
      expect(find.text('अच्युतम केशवम'), findsOneWidget);
      expect(find.text('श्री रामचंद्र कृपालु'), findsOneWidget);
    });

    testWidgets('BhajanScreen category chips filter bhajans by deity', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Initially shows all bhajans
      expect(find.text('अच्युतम केशवम'), findsOneWidget);
      expect(find.text('श्री रामचंद्र कृपालु'), findsOneWidget);

      // Tap on 'विठ्ठल' category chip
      await tester.tap(find.text('विठ्ठल'));
      await tester.pumpAndSettle();

      // Vitthal bhajans should be visible
      expect(find.text('विठ्ठल विठ्ठल जय हरी'), findsOneWidget);
      // Krishna bhajan should be filtered out
      expect(find.text('अच्युतम केशवम'), findsNothing);
    });

    testWidgets('Searching a bhajan filters the list dynamically', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Type "शंभू" into the search bar
      await tester.enterText(find.byType(TextField), 'शंभू');
      await tester.pumpAndSettle();

      // Should show Har Har Shambhu
      expect(find.text('हर हर शंभू शिव महादेवा'), findsOneWidget);
      // Other bhajans should not be visible
      expect(find.text('अच्युतम केशवम'), findsNothing);
    });

    testWidgets('Tapping a bhajan card opens AartiAltarScreen with lyrics', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      // Tap the first bhajan card (Achyutam Keshavam)
      await tester.tap(find.text('अच्युतम केशवम'));
      await tester.pumpAndSettle();

      // Verify AartiAltarScreen is pushed onto the navigator
      expect(find.byType(AartiAltarScreen), findsOneWidget);
    });
  });
}
