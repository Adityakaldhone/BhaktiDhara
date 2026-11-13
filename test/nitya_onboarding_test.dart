import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/data/datasources/bhakti_deity_catalog.dart';
import 'package:nitya_aarti/data/repositories/aarti_repository_impl.dart';
import 'package:nitya_aarti/domain/logic/ishta_devta.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/aarti_favorites_provider.dart';
import 'package:nitya_aarti/presentation/providers/horoscope_provider.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/nitya_onboarding_providers.dart';
import 'package:nitya_aarti/presentation/screens/altar_screen.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';
import 'package:nitya_aarti/presentation/screens/ishta_devta_screen.dart';
import 'package:nitya_aarti/presentation/widgets/nitya_pin_sheet.dart';
import 'package:nitya_aarti/services/aarti_reminder_service.dart';
import 'package:nitya_aarti/services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Ishta Devta', () {
    test('lists every deity, popular first, each shown one playable', () async {
      final catalog = await AartiRepositoryImpl().fetchCatalog();
      final deities = ishtaDeities();
      expect(deities.length, kBhaktiDeities.length);
      expect(
        deities.take(kIshtaDeityKeys.length).map((d) => d.key),
        kIshtaDeityKeys,
      );
      for (final deity in deities) {
        final aarti = mainAartiFor(deity, catalog);
        if (kIshtaDeityKeys.contains(deity.key)) {
          expect(aarti, isNotNull, reason: '${deity.key} has no aarti');
        }
        if (aarti != null) {
          expect(aarti.youtubeVideoId, isNotEmpty, reason: '${deity.key} has no audio');
        }
      }
    });

    test('prefers an item tagged Aarti over chalisa / stotra', () async {
      final catalog = await AartiRepositoryImpl().fetchCatalog();
      final hanuman = ishtaDeities().firstWhere((d) => d.key == 'Lord Hanuman');
      final aarti = mainAartiFor(hanuman, catalog)!;
      expect(aarti.tags.map((t) => t.toLowerCase()), contains('aarti'));
    });

    testWidgets('tapping a deity saves it, pins its aarti and opens Home',
        (tester) async {
      final container = ProviderContainer(
        overrides: [localeProvider.overrideWith((ref) => const Locale('hi'))],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('hi'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('hi'), Locale('mr')],
            home: IshtaDevtaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('आपके इष्ट देव कौन हैं?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ishta-Lord Ganesha')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(container.read(ishtaDevtaProvider), 'Lord Ganesha');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ishta_devta_key'), 'Lord Ganesha');

      expect(find.byType(AartiAltarScreen), findsNothing);
      expect(find.byType(MandirDashboardScreen), findsOneWidget);
      final catalog = await AartiRepositoryImpl().fetchCatalog();
      final ganesha = kBhaktiDeities.firstWhere((d) => d.key == 'Lord Ganesha');
      expect(container.read(aartiFavoritesProvider), [mainAartiFor(ganesha, catalog)!.id]);
    });

    testWidgets('changing from More replaces the old ishta aarti and returns',
        (tester) async {
      final catalog = await AartiRepositoryImpl().fetchCatalog();
      String mainAartiId(String key) =>
          mainAartiFor(kBhaktiDeities.firstWhere((d) => d.key == key), catalog)!.id;
      final ganeshaAarti = mainAartiId('Lord Ganesha');
      final shivaAarti = mainAartiId('Lord Shiva');
      SharedPreferences.setMockInitialValues({
        'ishta_devta_key': 'Lord Ganesha',
        'bhaktidhara_nitya_aartis_v1': [ganeshaAarti, 'hearted_aarti'],
      });
      final container = ProviderContainer(
        overrides: [localeProvider.overrideWith((ref) => const Locale('hi'))],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('hi'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IshtaDevtaScreen(changing: true),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('अपने इष्ट देव बदलें'), findsOneWidget);
      expect(find.byKey(const Key('ishta-skip')), findsNothing);

      final shivaTile = find.byKey(const Key('ishta-Lord Shiva'));
      await tester.ensureVisible(shivaTile);
      await tester.pumpAndSettle();
      await tester.tap(shivaTile);
      await tester.pumpAndSettle();

      expect(container.read(ishtaDevtaProvider), 'Lord Shiva');
      expect(find.byType(IshtaDevtaScreen), findsNothing);
      expect(find.byType(AartiAltarScreen), findsNothing);
      expect(container.read(aartiFavoritesProvider), [shivaAarti, 'hearted_aarti']);
    });
  });

  group('Nitya pin sheet', () {
    test('offered once: always after onboarding, otherwise only with no pins', () {
      expect(
        NityaPinSheet.shouldOffer(alreadyShown: false, fromOnboarding: true, hasPins: true),
        isTrue,
      );
      expect(
        NityaPinSheet.shouldOffer(alreadyShown: false, fromOnboarding: false, hasPins: false),
        isTrue,
      );
      expect(
        NityaPinSheet.shouldOffer(alreadyShown: false, fromOnboarding: false, hasPins: true),
        isFalse,
      );
      expect(
        NityaPinSheet.shouldOffer(
          alreadyShown: false,
          fromOnboarding: false,
          hasPins: true,
          hasIshta: true,
        ),
        isTrue,
      );
      expect(
        NityaPinSheet.shouldOffer(alreadyShown: true, fromOnboarding: true, hasPins: false),
        isFalse,
      );
    });

    test('pin adds to the front without toggling an existing pin off', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(aartiFavoritesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await notifier.pin('shiv_aarti');
      await notifier.pin('ganesh_aarti');
      await notifier.pin('ganesh_aarti');

      expect(container.read(aartiFavoritesProvider), ['ganesh_aarti', 'shiv_aarti']);
    });
  });

  group('Aarti reminders', () {
    test('default off and persisted after save', () async {
      expect((await AartiReminderService.load()).any, isFalse);

      await AartiReminderService.save(
        const AartiReminderSettings(evening: true),
        lang: 'hi',
        aartiId: 'ganesh_aarti',
      );
      final saved = await AartiReminderService.load();
      expect(saved.evening, isTrue);
      expect(saved.kakad, isFalse);
    });

    test('reminder text names the aarti in the devotee language', () {
      final aarti = PushNotificationService.findAartiById('ganesh_aarti')!;
      final hi = AartiReminderService.eveningText('hi', aarti);
      expect(hi.title, contains('संध्या आरती'));
      expect(hi.body, contains(aarti.localizedTitle('hi')));

      final mr = AartiReminderService.kakadText('mr', null);
      expect(mr.title, contains('काकड'));
      expect(AartiReminderService.eveningText('en', null).title, contains('Sandhya'));
    });

    test('regional aartis are found for reminder / push taps', () {
      expect(PushNotificationService.findAartiById('ganesh_aarti'), isNotNull);
      expect(PushNotificationService.findAartiById('missing_id'), isNull);
    });
  });

  group('Morning horoscope push', () {
    test('opt-in for new installs, kept for existing subscribers', () {
      expect(MorningReminderNotifier.resolveInitial(), isFalse);
      expect(
        MorningReminderNotifier.resolveInitial(subscribedTopics: ['all', 'lang_hi']),
        isFalse,
      );
      expect(
        MorningReminderNotifier.resolveInitial(
          subscribedTopics: ['all', 'morning_horoscope'],
        ),
        isTrue,
      );
      expect(
        MorningReminderNotifier.resolveInitial(
          saved: false,
          subscribedTopics: ['morning_horoscope'],
        ),
        isFalse,
      );
    });

    test('a fresh install starts with the morning push off', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(morningReminderEnabledProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(morningReminderEnabledProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('morning_horoscope_push_enabled'), isFalse);
    });
  });
}
