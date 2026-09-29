import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/panchang_city.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/panchang_provider.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';
import 'package:nitya_aarti/presentation/screens/panchang_screen.dart';
import 'package:nitya_aarti/services/gemini_panchang_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vedic Panchang Unit & Widget Tests', () {
    test('GeminiPanchangService calculates complete authentic Vedic Panchang',
        () async {
      final service = GeminiPanchangService();
      final date = DateTime(2026, 9, 25); // Friday

      final panchangMr = await service.getPanchang(
        date: date,
        city: kDefaultCity,
        langCode: 'mr',
      );

      expect(panchangMr.dayName, equals('शुक्रवार'));
      expect(panchangMr.cityName, equals('पुणे'));
      expect(panchangMr.tithi, isNotEmpty);
      expect(panchangMr.paksha, isNotEmpty);
      expect(panchangMr.nakshatra, isNotEmpty);
      expect(panchangMr.yoga, isNotEmpty);
      expect(panchangMr.karana, isNotEmpty);
      expect(panchangMr.sunrise, isNotEmpty);
      expect(panchangMr.sunset, isNotEmpty);
      expect(panchangMr.abhijitMuhurat, isNotEmpty);
      expect(panchangMr.rahuKaal, isNotEmpty);
      expect(panchangMr.dailyMantra, isNotEmpty);

      // Hindi verification
      final panchangHi = await service.getPanchang(
        date: date,
        city: kDefaultCity,
        langCode: 'hi',
      );
      expect(panchangHi.dayName, equals('शुक्रवार'));
      expect(panchangHi.paksha, contains('पक्ष'));

      // English verification
      final panchangEn = await service.getPanchang(
        date: date,
        city: kDefaultCity,
        langCode: 'en',
      );
      expect(panchangEn.dayName, equals('Friday'));
      expect(panchangEn.paksha, contains('Paksha'));

      // Location-dependency verification: Kolkata is further east than Pune
      final kolkata =
          kPopularPanchangCities.firstWhere((c) => c.id == 'kolkata');
      final panchangKolkata = await service.getPanchang(
        date: date,
        city: kolkata,
        langCode: 'en',
      );
      // Sunrise in Kolkata must be earlier than Pune
      expect(panchangKolkata.sunrise, isNot(equals(panchangEn.sunrise)));
    });

    testWidgets('PanchangScreen renders aesthetic Vedic calendar elements',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1400));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('mr')),
            selectedPanchangCityProvider.overrideWith((ref) => kDefaultCity),
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
            home: PanchangScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check App bar title
      expect(find.text('दैनिक पंचांग'), findsOneWidget);

      // Check City location selector strip
      expect(find.text('पंचांग स्थान:'), findsOneWidget);
      expect(find.text('पुणे (महाराष्ट्र)'), findsOneWidget);

      // Check Date Navigation buttons
      expect(find.text('काल'), findsOneWidget);
      expect(find.text('आज'), findsOneWidget);
      expect(find.text('उद्या'), findsOneWidget);

      // Today card answers the key questions first
      final todayCard = find.byKey(const Key('panchang-today-card'));
      expect(todayCard, findsOneWidget);
      expect(
        find.descendant(of: todayCard, matching: find.text('सर्वोत्तम शुभ वेळ')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: todayCard, matching: find.text('ही वेळ टाळा')),
        findsOneWidget,
      );

      // One schedule with every good and bad window
      expect(find.text('शुभ व अशुभ वेळा'), findsOneWidget);
      for (final name in [
        'ब्रह्म मुहूर्त',
        'अमृत काळ',
        'विजय मुहूर्त',
        'गोधूलि मुहूर्त',
        'यमगंड',
        'गुलिक काळ',
        'दुर्मुहूर्त',
        'भद्रा काळ',
      ]) {
        await tester.scrollUntilVisible(
          find.text(name),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('अभिजीत मुहूर्त'), findsWidgets);
      expect(find.text('राहु काळ'), findsWidgets);

      // Sun & Moon
      await tester.scrollUntilVisible(
        find.text('चंद्रास्त'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('सूर्य व चंद्र'), findsOneWidget);
      expect(find.text('सूर्योदय'), findsOneWidget);
      expect(find.text('सूर्यास्त'), findsOneWidget);
      expect(find.text('चंद्रोदय'), findsOneWidget);

      // Full Panchang stays one tap away and still shows every limb
      await tester.scrollUntilVisible(
        find.text('संपूर्ण पंचांग पहा'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('नक्षत्र'), findsNothing);
      await tester.tap(find.text('संपूर्ण पंचांग पहा'));
      await tester.pumpAndSettle();
      for (final label in [
        'तिथी',
        'वार',
        'नक्षत्र',
        'योग',
        'करण',
        'सूर्य राशी',
        'चंद्र राशी',
        'विक्रम संवत',
        'शक संवत',
        'संवत्सर',
        'ऋतू',
        'अयन',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(label), findsOneWidget);
      }
      // Tap City location pill to open City Selection Modal Sheet
      await tester.tap(find.text('पुणे (महाराष्ट्र)'));
      await tester.pumpAndSettle();

      // Verify City Selection Bottom Sheet is displayed
      expect(find.text('स्थान / शहर निवडा'), findsOneWidget);
      expect(find.text('उज्जैन (महाकाल)'), findsOneWidget);

      // Select Ujjain from the sheet
      await tester.tap(find.text('उज्जैन (महाकाल)'));
      await tester.pumpAndSettle();

      // Verify selected city updated
      expect(find.text('उज्जैन (महाकाल) (मध्य प्रदेश)'), findsOneWidget);
    });

    for (final lang in ['mr', 'hi', 'en']) {
      testWidgets('PanchangScreen fits a small phone in $lang',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 740));
        addTearDown(() async => await tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeProvider.overrideWith((ref) => Locale(lang)),
              selectedPanchangCityProvider.overrideWith((ref) => kDefaultCity),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
              locale: Locale(lang),
              home: const PanchangScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final details = find.byKey(const Key('panchang-full-details'));
        await tester.scrollUntilVisible(
          details,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(details);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Dashboard bottom navigation switches to Panchang tab',
        (WidgetTester tester) async {
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

      // Verify Panchang icon is present in BottomNavigationBar
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);

      // Tap Panchang tab
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();

      // Verify PanchangScreen is loaded and visible
      expect(find.byType(PanchangScreen), findsOneWidget);
      expect(find.text('दैनिक पंचांग'), findsOneWidget);
    });
  });
}
