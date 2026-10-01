import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/horoscope.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';
import 'package:nitya_aarti/presentation/screens/horoscope_screen.dart';
import 'package:nitya_aarti/services/gemini_horoscope_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    testWidgets('HoroscopeScreen renders Rashi carousel and reading content',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 3600));
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
      expect(find.text('उद्या'), findsOneWidget);
      expect(find.text('साप्ताहिक'), findsOneWidget);

      // Check Rashi symbol and name
      expect(find.text('मेष'), findsWidgets);
      expect(find.text('♈'), findsWidgets);

      // Check Phase 4 Personalized Lucky Meter
      expect(find.text('तुमचे वैयक्तिक भाग्य मीटर (नावावरून)'), findsOneWidget);
      expect(find.text('तुमच्या नावाचे पहिले अक्षर निवडा:'), findsOneWidget);
      expect(find.text('अक्षर: \'अ\''), findsOneWidget);

      // Test tapping an initial chip (e.g. 'स')
      await tester.tap(find.text('स').first);
      await tester.pumpAndSettle();
      expect(find.text('अक्षर: \'स\''), findsOneWidget);

      // Check Phase 1 Caution card
      expect(find.text('सावधगिरीचा इशारा (आज काय टाळावे?)'), findsOneWidget);

      // Check Phase 2 Hourly Time-Slot Forecast
      expect(find.text('वेळेनुसार दैनिक काळ व भविष्य'), findsOneWidget);
      expect(find.text('सकाळ (प्रातःकाल ऊर्जा)'), findsOneWidget);
      expect(find.text('दुपार (निर्णय व व्यवहार)'), findsOneWidget);
      expect(find.text('संध्याकाळ (कौटुंबिक व विश्रांती)'), findsOneWidget);

      // Check Phase 3 Compatibility & Deity section
      expect(find.text('आजचे अनुकूल भागीदार व मैत्री रास'), findsOneWidget);
      expect(find.text('अनुकूल मैत्री रास'), findsOneWidget);
      expect(find.text('सावध राहावयाची रास'), findsOneWidget);
      expect(find.text('आजची इष्टदेवता व ग्रह शांती बीजमंत्र'), findsOneWidget);

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

      // Check remedy and aspect cards
      expect(find.text('आजचा विशेष सिद्ध उपाय'), findsOneWidget);
      expect(find.text('कार्य व आर्थिक स्थिती'), findsOneWidget);

      // Check Phase 6 Morning 6 AM Notification Card
      expect(find.text('⏰ सकाळी ६:०० ची राशीभविष्य सूचना'), findsOneWidget);
      expect(find.text('🔔 सूचना कशी दिसेल ते पहा'), findsOneWidget);
    });

    testWidgets('HoroscopeScreen opens with initialRashiId deep-link',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 3600));
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
              focusSection: 'caution',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('वृश्चिक'), findsWidgets);
      expect(find.text('सावधगिरीचा इशारा (आज काय टाळावे?)'), findsOneWidget);
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
  });
}
