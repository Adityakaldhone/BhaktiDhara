import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/horoscope.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';
import 'package:nitya_aarti/presentation/screens/horoscope_screen.dart';
import 'package:nitya_aarti/services/gemini_horoscope_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SystemChannels.system.setMessageHandler(null);
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (TestWidgetsFlutterBinding.instance.transientCallbackCount > 0) {
      TestWidgetsFlutterBinding.instance.handleBeginFrame(Duration.zero);
      TestWidgetsFlutterBinding.instance.handleDrawFrame();
    }
  });

  group('Horoscope Unit & Widget Tests', () {
    test('All 12 Vedic Rashis are configured', () {
      expect(kAllRashis.length, equals(12));
      final names = kAllRashis.map((r) => r.nameMr).toList();
      expect(names, contains('मेष'));
      expect(names, contains('वृषभ'));
      expect(names, contains('मिथुन'));
      expect(names, contains('कर्क'));
      expect(names, contains('सिंह'));
      expect(names, contains('कन्या'));
      expect(names, contains('तुला'));
      expect(names, contains('वृश्चिक'));
      expect(names, contains('धनु'));
      expect(names, contains('मकर'));
      expect(names, contains('कुंभ'));
      expect(names, contains('मीन'));
    });

    test('GeminiHoroscopeService generates valid reading with fallback', () async {
      final service = GeminiHoroscopeService();
      final reading = await service.getHoroscope(
        rashi: kAllRashis.first,
        period: 'today',
        langCode: 'mr',
      );

      expect(reading.rashiId, equals('aries'));
      expect(reading.summary, isNotEmpty);
      expect(reading.career, isNotEmpty);
      expect(reading.health, isNotEmpty);
      expect(reading.love, isNotEmpty);
      expect(reading.luckyNumber, isNotEmpty);
      expect(reading.luckyColor, isNotEmpty);
      expect(reading.remedy, isNotEmpty);
      expect(reading.auspiciousPercentage, greaterThan(50));
    });

    test('GeminiHoroscopeService consults Vedic AI for user question', () async {
      final service = GeminiHoroscopeService();
      final consult = await service.consultVedicAi(
        rashi: kAllRashis.first,
        question: 'नोकरीमध्ये कधी यश मिळेल?',
        langCode: 'mr',
      );

      expect(consult.headline, isNotEmpty);
      expect(consult.astrologicalAspect, isNotEmpty);
      expect(consult.guidance, isNotEmpty);
      expect(consult.remedy, isNotEmpty);
      expect(consult.favorableTiming, isNotEmpty);
    });

    test('GeminiHoroscopeService produces valid structured HoroscopePage with presentation', () async {
      final service = GeminiHoroscopeService();
      final page = await service.getHoroscopePage(
        rashi: kAllRashis.first,
        period: 'today',
        langCode: 'mr',
        city: HoroscopeCity(name: 'Pune', latitude: 18.5204, longitude: 73.8567),
      );

      expect(page.symbol, equals('♈'));
      expect(page.signTitle, contains('मेष'));
      expect(page.headline, isNotEmpty);
      expect(page.fullSections.length, equals(5));
      expect(page.summarySections.length, equals(4));
      expect(page.ephemerisSource, isNotEmpty);
    });

    testWidgets('HoroscopeScreen renders Rashi carousel and reading content',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 4800));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

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
            home: HoroscopeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title
      expect(find.text('दैनिक राशीभविष्य'), findsOneWidget);

      // Check period selector tabs
      expect(find.text('आज'), findsOneWidget);
      expect(find.text('उद्या'), findsNothing);
      expect(find.text('साप्ताहिक'), findsOneWidget);

      // Check Rashi symbol and name
      expect(find.text('मेष'), findsWidgets);
      expect(find.text('♈'), findsWidgets);

      // Check new HoroscopeDetailContent sections
      expect(find.text('राशीभविष्य'), findsWidgets);
      expect(find.text('जीवनाचे पैलू'), findsOneWidget);
      expect(find.text('कृतीसाठी मार्गदर्शन'), findsOneWidget);
      expect(find.text('शुभ संकेत'), findsOneWidget);

      // Check Phase 5 Vedic AI Consult Card
      expect(find.text('वेदिक AI ज्योतिष मार्गदर्शन'), findsOneWidget);
      expect(find.text('खालीलपैकी एक प्रश्न निवडा किंवा स्वतःचा विचारा:'), findsOneWidget);
      expect(find.text('💼 नोकरी/व्यवसायात कधी यश मिळेल?'), findsOneWidget);

      // Test tapping suggested question chip
      await tester.tap(find.text('💼 नोकरी/व्यवसायात कधी यश मिळेल?'));
      await tester.pumpAndSettle();

      // Check results
      expect(find.text('ग्रहगोचर संकेत व सारांश'), findsOneWidget);
      expect(find.text('दुसरा प्रश्न विचारा'), findsOneWidget);

      // Check Phase 6 Morning 6 AM Notification Card
      expect(find.text('⏰ सकाळी ६:०० ची राशीभविष्य सूचना'), findsOneWidget);
      expect(find.text('🔔 सूचना कशी दिसेल ते पहा'), findsOneWidget);
    });

    testWidgets('HoroscopeScreen opens with initialRashiId deep-link',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 4800));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

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
            home: HoroscopeScreen(
              initialRashiId: 'scorpio',
              focusSection: 'actions',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('वृश्चिक'), findsWidgets);
      expect(find.text('कृतीसाठी मार्गदर्शन'), findsOneWidget);
    });

    testWidgets('Dashboard bottom navigation switches to Horoscope tab',
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

      // Tap Horoscope tab in bottom navigation
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      // Verify HoroscopeScreen is visible
      expect(find.byType(HoroscopeScreen), findsOneWidget);
      expect(find.text('दैनिक राशीभविष्य'), findsOneWidget);
    });

    testWidgets('HoroscopeScreen renders cleanly in English (en-US) without RenderFlex overflow',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 2400));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) => const Locale('en')),
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
            locale: Locale('en'),
            home: HoroscopeScreen(
              initialRashiId: 'taurus',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Taurus'), findsWidgets);
      expect(find.text("Today's Forecast"), findsOneWidget);
      expect(find.text("Action Guidance"), findsOneWidget);
      expect(find.text("Life Aspects"), findsOneWidget);
      expect(find.text("Auspicious Signs"), findsOneWidget);
      expect(find.text("Sacred Vedic Remedies"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
