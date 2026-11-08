import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:nitya_aarti/data/datasources/catalog.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/review_provider.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/services/review_service.dart';
import 'package:nitya_aarti/services/review_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeInAppReview implements InAppReview {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async {}

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required ReviewService reviewService,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        reviewServiceProvider.overrideWithValue(reviewService),
        localeProvider.overrideWith((ref) => const Locale('mr')),
      ],
      child: MaterialApp(
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
        locale: const Locale('mr'),
        home: child,
      ),
    );
  }

  group('Aarti Back Press Review Popup Flow', () {
    late SharedPreferences prefs;
    late ReviewStorageService storage;
    late FakeInAppReview fakeInAppReview;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = ReviewStorageService(prefs);
      fakeInAppReview = FakeInAppReview();
    });

    testWidgets(
        '1st time on app: pressing back from aarti does NOT open review popup',
        (tester) async {
      // 1st open
      await storage.recordAppOpen();
      final reviewService = ReviewService(storage, fakeInAppReview);

      final aarti = kDevotionalCatalog.first;

      await tester.pumpWidget(
        createTestWidget(
          reviewService: reviewService,
          child: AartiAltarScreen(aarti: aarti),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on-screen back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/aarti_screen/back_button.webp',
      );
      expect(backButtonFinder, findsOneWidget);

      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Review dialog title should NOT appear
      expect(find.text('तुमचा भक्ती अनुभव कसा होता?'), findsNothing);
    });

    testWidgets(
        '2nd time on app and has not rated: pressing back from aarti AUTOMATICALLY opens review popup',
        (tester) async {
      // 1st open + 2nd open (second time on the app)
      await storage.recordAppOpen();
      await storage.recordAppOpen();
      expect(storage.appOpenCount, greaterThanOrEqualTo(2));
      expect(storage.hasRated, isFalse);

      final reviewService = ReviewService(storage, fakeInAppReview);
      final aarti = kDevotionalCatalog.first;

      await tester.pumpWidget(
        createTestWidget(
          reviewService: reviewService,
          child: AartiAltarScreen(aarti: aarti),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on-screen back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/aarti_screen/back_button.webp',
      );
      expect(backButtonFinder, findsOneWidget);

      await tester.tap(backButtonFinder);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Review dialog is automatically opened!
      expect(find.text('तुमचा भक्ती अनुभव कसा होता?'), findsOneWidget);
      expect(find.text('भक्तिधारा सोबतची तुमची साधना'), findsOneWidget);
    });

    testWidgets(
        'User has already rated: pressing back from aarti does NOT open review popup',
        (tester) async {
      // 2nd open, but user already rated previously
      await storage.recordAppOpen();
      await storage.recordAppOpen();
      await storage.setHasRated();
      expect(storage.hasRated, isTrue);

      final reviewService = ReviewService(storage, fakeInAppReview);
      final aarti = kDevotionalCatalog.first;

      await tester.pumpWidget(
        createTestWidget(
          reviewService: reviewService,
          child: AartiAltarScreen(aarti: aarti),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on-screen back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/aarti_screen/back_button.webp',
      );
      expect(backButtonFinder, findsOneWidget);

      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // Dialog does NOT appear
      expect(find.text('तुमचा भक्ती अनुभव कसा होता?'), findsNothing);
    });
  });
}
