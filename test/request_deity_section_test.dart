import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/remote_config_provider.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_aarti_list_screen.dart';
import 'package:nitya_aarti/presentation/screens/more_screen.dart';
import 'package:nitya_aarti/presentation/screens/request_deity_aarti_screen.dart';
import 'package:nitya_aarti/presentation/widgets/request_deity_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapApp({required Widget home, Locale locale = const Locale('hi')}) {
    return ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => locale),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
        home: home,
      ),
    );
  }

  void unmountOnTearDown(WidgetTester tester) {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  testWidgets('Home exposes request card and opens simple 24h request page',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    unmountOnTearDown(tester);

    await tester.pumpWidget(wrapApp(home: const MandirDashboardScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final cardFinder = find.byKey(const Key('home-request-section-card'));
    expect(cardFinder, findsOneWidget);
    expect(find.text('नया देवता या आरती जोड़ें'), findsOneWidget);

    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.byType(RequestDeityAartiScreen), findsOneWidget);
    expect(find.text('YouTube वीडियो लिंक (ज़रूरी नहीं):'), findsOneWidget);

    // Tapping Send with an empty field guides 40+ users gently instead of failing silently.
    await tester.tap(find.byKey(const Key('dedicated-request-submit')));
    await tester.pump();
    expect(find.text('कृपया पहले ऊपर नाम लिखें 🙏'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('dedicated-request-name-input')),
      'माँ बगलामुखी',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('dedicated-request-submit')));
    await tester.pumpAndSettle();

    // Automatic 24-hour confirmation dialog pops up immediately.
    expect(find.text('आपकी विनती भेज दी गई है! 🙏'), findsOneWidget);
    expect(find.textContaining('२४ घंटे के अंदर'), findsWidgets);

    await tester.tap(find.byKey(const Key('request-sent-dialog-ok')));
    await tester.pumpAndSettle();

    expect(find.text('माँ बगलामुखी'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('submitted_deity_requests_v1'), contains('माँ बगलामुखी'));
  });

  testWidgets('More screen embeds simple single-input Deity/Aarti request section',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    unmountOnTearDown(tester);

    await tester.pumpWidget(
      wrapApp(home: const MoreScreen(), locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('more-request-deity-section')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('more-request-name-input')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('more-request-name-input')),
      'Kalbhairav Aarti',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('more-request-submit')));
    await tester.tap(find.byKey(const Key('more-request-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Request Sent! 🙏'), findsOneWidget);
    expect(find.textContaining('24 hours'), findsWidgets);
    await tester.tap(find.byKey(const Key('request-sent-dialog-ok')));
    await tester.pumpAndSettle();
    expect(find.text('Kalbhairav Aarti'), findsOneWidget);
  });

  testWidgets('Deity Aarti list shows footer CTA card and opens request screen',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    unmountOnTearDown(tester);

    await tester.pumpWidget(
      wrapApp(home: const DeityAartiListScreen(deity: 'Lord Ganesha')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('aarti-list-request-card')),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aarti-list-request-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('aarti-list-request-card')));
    await tester.pumpAndSettle();
    expect(find.byType(RequestDeityAartiScreen), findsOneWidget);
  });

  testWidgets('showRequestDeitySheet shows 24h confirmation dialog after submit',
      (tester) async {
    await tester.pumpWidget(
      wrapApp(
        locale: const Locale('hi'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showRequestDeitySheet(
                context,
                lang: 'hi',
                source: 'test_sheet',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'श्री ज्योतिबा');
    await tester.pump();
    await tester.tap(find.text('अनुरोध भेजें 🙏'));
    await tester.pumpAndSettle();

    expect(find.text('आपकी विनती भेज दी गई है! 🙏'), findsOneWidget);
  });
}
