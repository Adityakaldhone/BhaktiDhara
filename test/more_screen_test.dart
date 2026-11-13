import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/screens/more_screen.dart';

void main() {
  Widget buildMoreScreen({Locale locale = const Locale('en')}) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('mr'),
        ],
        home: const MoreScreen(),
      ),
    );
  }

  testWidgets('MoreScreen renders redesign components in English', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildMoreScreen());
    await tester.pumpAndSettle();

    // Screen title
    expect(find.text('More'), findsOneWidget);

    // Hero Card
    expect(find.byKey(const Key('more-ishta-devta')), findsOneWidget);
    expect(find.text('ISHTA DEVTA'), findsOneWidget);
    expect(find.text('View deity'), findsOneWidget);

    // Daily practice section
    expect(find.text('Daily practice'), findsOneWidget);
    expect(find.byKey(const Key('more-aarti-reminders')), findsOneWidget);
    expect(find.text('Aarti Reminders'), findsOneWidget);
    expect(find.text('Kakad 6:00 AM'), findsOneWidget);
    expect(find.text('Sandhya 6:30 PM'), findsOneWidget);

    // Bento cards
    expect(find.byKey(const Key('more-panchang')), findsOneWidget);
    expect(find.text('Panchang Calendar'), findsOneWidget);
    expect(find.text('Tithi, festivals & nakshatra'), findsOneWidget);

    expect(find.byKey(const Key('more-granth')), findsOneWidget);
    expect(find.text('Granth'), findsOneWidget);
    expect(find.text('Gita, Puranas & scriptures'), findsOneWidget);

    // Vedic astrology section
    expect(find.text('Vedic astrology'), findsOneWidget);
    expect(find.byKey(const Key('more-kundali')), findsOneWidget);
    expect(find.text('Kundali Chart'), findsOneWidget);
    expect(find.text('Vedic birth chart'), findsOneWidget);

    expect(find.byKey(const Key('more-milan')), findsOneWidget);
    expect(find.text('Kundali Milan'), findsOneWidget);
    expect(find.text('36-guna matching & Manglik check'), findsOneWidget);

    expect(find.byKey(const Key('more-grahan')), findsOneWidget);
    expect(find.text('Grahan (Eclipses)'), findsOneWidget);
    expect(find.text('Solar & lunar eclipses, sutak & reminders'), findsOneWidget);
  });

  testWidgets('MoreScreen renders localized text in Marathi and Hindi', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Marathi
    await tester.pumpWidget(buildMoreScreen(locale: const Locale('mr')));
    await tester.pumpAndSettle();

    expect(find.text('अधिक'), findsOneWidget);
    expect(find.text('इष्ट दैवत'), findsOneWidget);
    expect(find.text('दर्शन करा'), findsOneWidget);
    expect(find.text('नित्य साधना'), findsOneWidget);
    expect(find.text('आरती आठवण'), findsOneWidget);
    expect(find.text('काकड 6:00 AM'), findsOneWidget);
    expect(find.text('संध्या 6:30 PM'), findsOneWidget);
    expect(find.text('पंचांग कॅलेंडर'), findsOneWidget);
    expect(find.text('वैदिक ज्योतिष'), findsOneWidget);
    expect(find.text('कुंडली'), findsOneWidget);
    expect(find.text('कुंडली मिलन'), findsOneWidget);

    // Hindi
    await tester.pumpWidget(buildMoreScreen(locale: const Locale('hi')));
    await tester.pumpAndSettle();

    expect(find.text('अधिक'), findsOneWidget);
    expect(find.text('इष्ट देव'), findsOneWidget);
    expect(find.text('दर्शन करें'), findsOneWidget);
    expect(find.text('दैनिक साधना'), findsOneWidget);
    expect(find.text('आरती रिमाइंडर'), findsOneWidget);
    expect(find.text('काकड़ 6:00 AM'), findsOneWidget);
    expect(find.text('संध्या 6:30 PM'), findsOneWidget);
    expect(find.text('पंचांग कैलेंडर'), findsOneWidget);
    expect(find.text('वैदिक ज्योतिष'), findsOneWidget);
    expect(find.text('कुंडली चार्ट'), findsOneWidget);
    expect(find.text('कुंडली मिलान'), findsOneWidget);
  });
}
