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

    testWidgets('HoroscopeScreen renders Rashi carousel and reading content',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1200));
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

      // Check remedy and aspect cards
      expect(find.text('आजचा विशेष सिद्ध उपाय'), findsOneWidget);
      expect(find.text('कार्य व आर्थिक स्थिती'), findsOneWidget);
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
