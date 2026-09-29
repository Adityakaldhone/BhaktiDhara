import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Dashboard Navbar & Language Dropdown Tests', () {
    testWidgets('Dashboard navbar has 4 tabs (Home, Bhajan, Horoscope, Panchang)',
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

      // Check BottomNavigationBar items
      final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.items.length, 4);
      expect(navBar.items[0].icon, isA<Icon>());
      expect((navBar.items[0].icon as Icon).icon, Icons.home_filled);
      expect(navBar.items[1].icon, isA<Icon>());
      expect((navBar.items[1].icon as Icon).icon, Icons.library_music_rounded);
      expect(navBar.items[2].icon, isA<Icon>());
      expect((navBar.items[2].icon as Icon).icon, Icons.auto_awesome);
      expect(navBar.items[3].icon, isA<Icon>());
      expect((navBar.items[3].icon as Icon).icon, Icons.calendar_month_rounded);

      // Verify "See All" button is gone
      expect(find.text('सर्व पहा'), findsNothing);
      expect(find.text('See All'), findsNothing);

      // Verify Language dropdown is present with down arrow
      expect(find.text('भाषा: मराठी'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsWidgets);
    });

    testWidgets('Tapping language dropdown displays radio button options and switches locale',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('mr')),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              return MaterialApp(
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
                locale: locale,
                home: const MandirDashboardScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state is Marathi
      expect(find.text('भाषा: मराठी'), findsOneWidget);

      // Tap the dropdown button
      await tester.tap(find.text('भाषा: मराठी'));
      await tester.pumpAndSettle();

      // Popup menu options with radio buttons should appear
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget); // Marathi is checked
      expect(find.byIcon(Icons.radio_button_off), findsNWidgets(2)); // Hindi and English are unchecked

      // Select Hindi
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();

      // Dropdown should now reflect Hindi
      expect(find.text('भाषा: हिंदी'), findsOneWidget);
      expect(container.read(localeProvider), const Locale('hi'));
    });
  });
}
