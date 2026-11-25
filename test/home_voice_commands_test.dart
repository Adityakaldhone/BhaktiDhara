import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nitya_aarti/features/voice_agent/data/voice_agent_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/domain/entities/aarti_item.dart';
import 'package:nitya_aarti/domain/entities/granth.dart';
import 'package:nitya_aarti/features/voice_agent/domain/home_voice_commands.dart';
import 'package:nitya_aarti/l10n/app_localizations.dart';
import 'package:nitya_aarti/presentation/providers/aarti_providers.dart';
import 'package:nitya_aarti/presentation/providers/granth_providers.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/screens/dashboard_screen.dart';
import 'package:nitya_aarti/presentation/screens/deity_aarti_list_screen.dart';

void main() {
  test(
    'Home commands agree with dataset labels and leave help questions to the guide',
    () {
      for (final split in ['plain', 'mixed', 'held_out']) {
        for (final line in File(
          'backend/datasets/home/$split.jsonl',
        ).readAsLinesSync()) {
          final messages = jsonDecode(line)['messages'];
          final text = messages[1]['content'] as String;
          final expected = jsonDecode(messages[2]['content'])['action'];
          final local = HomeCommand.parse(text);
          final prediction = HomeCommand.fromPrediction(expected);
          if (local == null && prediction != null) {
            expect(HomeCommand.mightReferToHome(text), isTrue, reason: text);
          }
          final cmd = local ?? prediction;
          final actual = switch (cmd) {
            SearchHome(:final query) => {'type': 'search_home', 'query': query},
            FilterHome(:final region) => {
              'type': 'filter_home',
              'region': region?.name ?? 'all',
            },
            OpenHomeResult(:final position, :final section) => {
              'type': 'open_home_result',
              'position': position,
              'section': section,
            },
            ReadHomeSearch() => {'type': 'read_home_search'},
            ReadHomeRegion() => {'type': 'read_home_region'},
            CancelHomeCommand() => {'type': 'none'},
            HomeExplanation() || null => null,
          };
          if (actual != null ||
              [
                'search_home',
                'filter_home',
                'open_home_result',
                'read_home_search',
                'read_home_region',
              ].contains(expected['type'])) {
            expect(actual, expected, reason: text);
          }
        }
      }
    },
  );

  testWidgets(
    'Home filters, searches, opens the displayed second item and goes back',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      GoogleFonts.config.allowRuntimeFetching = false;
      final items = [
        for (final id in ['rj_other', 'guj_one', 'guj_two'])
          AartiItem.fromJson({'id': id, 'title': 'Morning $id', 'deity': id}),
      ];
      final loadingItems = Completer<List<AartiItem>>();
      final container = ProviderContainer(
        overrides: [
          localeProvider.overrideWith((ref) => const Locale('en')),
          aartiCatalogProvider.overrideWith((ref) => loadingItems.future),
          granthBooksProvider.overrideWith(
            (ref) async => [
              GranthBook.fromJson({
                'slug': 'morning-book',
                'title': {'en': 'Morning Book'},
              }),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: MandirDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      HomeVoiceReply command(String q) => container
          .read(homeVoiceBindingProvider)
          .activeHandler!
          .call()!
          .call(q, 'en')!;
      HomeVoiceReply modelCommand(String text, HomeCommand prediction) =>
          container.read(homeVoiceBindingProvider).activeHandler!.call()!(
            text,
            'en',
            prediction: prediction,
          )!;
      for (final q in [
        'Do not bring up the second aarti',
        'उस किताब को रहने दो',
        'ती आरती उघडू नको',
        'third result mat kholna',
      ]) {
        expect(command(q).apply, isNull, reason: q);
        expect(find.byType(MandirDashboardScreen), findsOneWidget);
      }
      final client = MockClient((request) async {
        if (request.method == 'GET') return http.Response('{}', 200);
        expect(request.url.path, endsWith('/home-control'));
        final text = jsonDecode(request.body)['text'];
        final action = text.contains('Gujarat')
            ? {'type': 'filter_home', 'region': 'gujarat'}
            : {'type': 'open_home_result', 'position': 2, 'section': 'all'};
        return http.Response(jsonEncode({'action': action}), 200);
      });
      const secondRequest = 'Bring up entry number two for me';
      expect(HomeCommand.parse(secondRequest), isNull);
      final ordinal = (await tester.runAsync(
        () => VoiceAgentService.predictHomeCommand(
          secondRequest,
          'en-IN',
          client: client,
        ),
      ))!;
      expect(modelCommand(secondRequest, ordinal).text, contains('loading'));
      loadingItems.complete(items);
      await tester.pump();
      const regionRequest = 'Narrow the collection down to Gujarat for me';
      final filter = (await tester.runAsync(
        () => VoiceAgentService.predictHomeCommand(
          regionRequest,
          'en-IN',
          client: client,
        ),
      ))!;
      modelCommand(regionRequest, filter).apply!();
      await tester.pump();
      expect(
        container.read(filteredCatalogProvider).requireValue.map((x) => x.id),
        ['guj_one', 'guj_two'],
      );
      expect(modelCommand(secondRequest, ordinal).text, 'Morning guj_two');
      command('Search for guj_one').apply!();
      await tester.pump();
      expect(modelCommand(secondRequest, ordinal).apply, isNull);
      expect(modelCommand(secondRequest, ordinal).text, contains('1 result'));
      expect(command('which region is selected?').text, contains('Gujarat'));
      command('Search for morning').apply!();
      expect(command('what am I searching for?').text, 'morning');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'morning',
      );
      await tester.pump();
      // The matching scripture precedes the two aartis in the Home list.
      expect(command('open the first book').text, 'Morning Book');
      expect(command('open the fourth result').apply, isNull);
      modelCommand(secondRequest, ordinal).apply!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<DeityAartiListScreen>(find.byType(DeityAartiListScreen))
            .initialItem!
            .id,
        'guj_one',
      );
      command('go back').apply!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      command('show all regions again').apply!();
      command('clear the search').apply!();
      await tester.pump();
      expect(container.read(selectedRegionProvider), isNull);
      expect(container.read(searchQueryProvider), '');
      expect(container.read(filteredCatalogProvider).requireValue.length, 3);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
