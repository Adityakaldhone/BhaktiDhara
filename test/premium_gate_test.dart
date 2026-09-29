import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/panchang_city.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/panchang_provider.dart';
import 'package:nitya_aarti/presentation/providers/premium_provider.dart';
import 'package:nitya_aarti/presentation/screens/horoscope_screen.dart';
import 'package:nitya_aarti/presentation/screens/panchang_screen.dart';
import 'package:nitya_aarti/presentation/widgets/premium_blurred_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Premium Membership & Half-Blurred Gate Tests', () {
    testWidgets('PremiumBlurredGate displays unlock banner and blur when user is free',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => PremiumNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBlurredGate(
                langCode: 'mr',
                title: 'संपूर्ण राशीभविष्य व उपाय अनलॉक करा',
                subtitle: 'करिअर, धनलाभ, कुटुंब व आरोग्याची अचूक माहिती मिळवा.',
                child: Text('Secret Vedic Astrological Remedy Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Free user must see the ₹20 offer banner and unlock button
      expect(find.text('विशेष ऑफर: फक्त ₹२० / महिना'), findsOneWidget);
      expect(find.text('संपूर्ण राशीभविष्य व उपाय अनलॉक करा'), findsOneWidget);
      expect(find.text('प्रीमियम अनलॉक करा — ₹२०'), findsOneWidget);

      // Child is rendered inside ImageFiltered blur
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(find.text('Secret Vedic Astrological Remedy Content'), findsOneWidget);
    });

    testWidgets('PremiumBlurredGate reveals content without blur when user has premium',
        (WidgetTester tester) async {
      final premiumNotifier = PremiumNotifier();
      await premiumNotifier.unlockPremium();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => premiumNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBlurredGate(
                langCode: 'mr',
                title: 'संपूर्ण राशीभविष्य व उपाय अनलॉक करा',
                subtitle: 'करिअर, धनलाभ, कुटुंब व आरोग्याची अचूक माहिती मिळवा.',
                child: Text('Secret Vedic Astrological Remedy Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Premium user must NOT see the blur or unlock card
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.text('विशेष ऑफर: फक्त ₹२० / महिना'), findsNothing);
      expect(find.text('प्रीमियम अनलॉक करा — ₹२०'), findsNothing);

      // Secret content is clear and accessible
      expect(find.text('Secret Vedic Astrological Remedy Content'), findsOneWidget);
    });

    testWidgets('Tapping Unlock Premium opens Paywall Sheet with ₹20/month details',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWith((ref) => PremiumNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PremiumBlurredGate(
                langCode: 'mr',
                title: 'संपूर्ण माहिती अनलॉक करा',
                subtitle: 'तपशील मिळवा',
                child: Text('Protected Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Unlock CTA button
      await tester.tap(find.text('प्रीमियम अनलॉक करा — ₹२०'));
      await tester.pumpAndSettle();

      // Verify Paywall sheet opens with ₹20 details
      expect(find.text('भक्तिधारा प्रीमियम'), findsOneWidget);
      expect(find.text('मासिक योजना'), findsOneWidget);
      expect(find.text('₹२० / महिना'), findsOneWidget);
      expect(find.text('८०% सूट'), findsOneWidget);
      expect(find.text('आत्ताच सबस्क्राइब करा • फक्त ₹२०'), findsOneWidget);

      // Tap Subscribe Now to activate premium
      await tester.tap(find.text('आत्ताच सबस्क्राइब करा • फक्त ₹२०'));
      await tester.pumpAndSettle();

      // The sheet should close and premium should be unlocked
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets(
      'HoroscopeScreen shows ₹20 badge in header and unlocks on purchase',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1400));
        addTearDown(() async => await tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeProvider.overrideWith((ref) => const Locale('mr')),
              isPremiumProvider.overrideWith((ref) => PremiumNotifier()),
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

        // Verify header has ₹20 badge
        expect(find.text('₹२०'), findsOneWidget);

        // Verify the unlock banner is displayed for the free user
        expect(find.text('संपूर्ण राशीभविष्य व उपाय अनलॉक करा'), findsOneWidget);
        expect(find.text('प्रीमियम अनलॉक करा — ₹२०'), findsOneWidget);
      },
      skip: true, // Preserved for future release when premium plan is re-enabled
    );

    testWidgets(
      'PanchangScreen shows ₹20 badge and protects deeper muhurats for free user',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1600));
        addTearDown(() async => await tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localeProvider.overrideWith((ref) => const Locale('mr')),
              selectedPanchangCityProvider.overrideWith((ref) => kDefaultCity),
              isPremiumProvider.overrideWith((ref) => PremiumNotifier()),
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

        // Verify header has ₹20 badge
        expect(find.text('₹२०'), findsOneWidget);

        // Verify the unlock banner for Panchang
        expect(find.text('सविस्तर पंचांग व शुभ मुहूर्त अनलॉक करा'), findsOneWidget);
        expect(find.text('विशेष ऑफर: फक्त ₹२० / महिना'), findsOneWidget);
      },
      skip: true, // Preserved for future release when premium plan is re-enabled
    );
  });
}
