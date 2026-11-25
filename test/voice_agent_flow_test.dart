import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nitya_aarti/data/datasources/marathi_aarti_catalog.dart';
import 'package:nitya_aarti/data/datasources/bundled_aarti_catalog.dart';
import 'package:nitya_aarti/features/voice_agent/domain/voice_action_dispatcher.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/presentation/providers/remote_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/horoscope.dart';
import 'package:nitya_aarti/domain/entities/jaap_progress.dart';
import 'package:nitya_aarti/domain/logic/jaap_streak.dart';
import 'package:nitya_aarti/features/voice_agent/data/voice_agent_service.dart';
import 'package:nitya_aarti/features/voice_agent/domain/local_voice_intent_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Rashi alias resolution', () {
    test('maps Vedic kumbh and English aquarius to aquarius', () {
      expect(resolveRashi('kumbh')?.id, 'aquarius');
      expect(resolveRashi('aquarius')?.id, 'aquarius');
      expect(resolveRashi('कुंभ')?.id, 'aquarius');
      expect(resolveRashi('कुम्भ')?.id, 'aquarius');
    });

    test('maps mesh / aries correctly', () {
      expect(resolveRashi('mesh')?.id, 'aries');
      expect(resolveRashi('aries')?.id, 'aries');
      expect(resolveRashi('मेष')?.id, 'aries');
    });
  });

  group('LocalVoiceIntentParser', () {
    test('opens aquarius horoscope for kumbh rashifal', () {
      final result = LocalVoiceIntentParser.parse(
        'show the kumbh rashifal',
        localeHint: 'en-IN',
      );
      expect(result.action.type, 'open_horoscope');
      expect(result.action.rashiId, 'aquarius');
    });

    test('opens aquarius for Marathi कुंभ राशीचे भविष्य', () {
      final result = LocalVoiceIntentParser.parse(
        'कुंभ राशीचे आजचे भविष्य दाखवा',
        localeHint: 'mr-IN',
      );
      expect(result.action.type, 'open_horoscope');
      expect(result.action.rashiId, 'aquarius');
      expect(result.responseText, contains('कुंभ'));
    });

    test('opens panchang for rahu kaal', () {
      final result = LocalVoiceIntentParser.parse(
        'आज का राहुकाल क्या है?',
        localeHint: 'hi-IN',
      );
      expect(result.action.type, 'open_panchang');
      expect(result.action.field, 'rahu_kaal');
    });

    test('opens jaap for नामजप', () {
      final result = LocalVoiceIntentParser.parse('jaap mala open');
      expect(result.action.type, 'start_jaap');
    });

    test('opens jaap for nam jap ASR spelling', () {
      final result = LocalVoiceIntentParser.parse('open nam jap');
      expect(result.action.type, 'start_jaap');
    });

    test('opens jaap for spoken spellings and casing', () {
      for (final query in [
        'jap',
        'japa',
        'naam jap',
        'nam jaap',
        'naamjaap',
        'namjaap',
        'Chant!',
        'नाम जाप',
        'जपमाळ',
      ]) {
        expect(
          LocalVoiceIntentParser.parse(query).action.type,
          'start_jaap',
          reason: query,
        );
      }
    });

    test('does not open jaap for partial words', () {
      for (final query in [
        'What is the capital of Japan?',
        'merchant',
        'Malaysia',
      ]) {
        expect(
          LocalVoiceIntentParser.parse(query).action.type,
          isNot('start_jaap'),
          reason: query,
        );
      }
    });

    test('resolves a catalog mantra with a Devanagari name', () {
      final result = LocalVoiceIntentParser.parse(
        'ॐ नमो नारायणाय का जाप शुरू करो',
      );
      expect(result.action.type, 'start_jaap');
      expect(result.action.mantraId, 'om_namo_narayanaya');
    });

    test('opens jaap with radha mantra', () {
      final result = LocalVoiceIntentParser.parse(
        'open naam jaap select radha mantra',
        localeHint: 'en-IN',
      );
      expect(result.action.type, 'start_jaap');
      expect(result.action.mantraId, 'radha');
    });

    test('prioritizes explicit jaap and selects the specific mantra', () {
      final cases = {
        'chant Shri Ram': 'shri_ram',
        'chant Jai Shri Ram': 'jai_shri_ram',
        'गायत्रीचा नामजप लावा': 'gayatri',
        'japa with Hare Krishna': 'hare_krishna',
        'chant Om Gam Ganapataye Namah': 'ganesha',
        'ॐ हं हनुमते नमः जप करा': 'hanuman',
      };
      for (final entry in cases.entries) {
        final result = LocalVoiceIntentParser.parse(entry.key);
        expect(result.action.type, 'start_jaap', reason: entry.key);
        expect(result.action.mantraId, entry.value, reason: entry.key);
      }
    });

    test(
      'recognizes read-only jaap history and festival calendar requests',
      () {
        final cases = {
          'show my naamjaap history': 'open_jaap_stats',
          'What is my japa streak?': 'open_jaap_stats',
          'माझ्या जपाची आकडेवारी दाखवा': 'open_jaap_stats',
          'open the festival calendar': 'open_calendar',
          'अखंड दिवा दाखवा': 'open_akhand_diya',
        };
        for (final entry in cases.entries) {
          expect(
            LocalVoiceIntentParser.parse(entry.key).action.type,
            entry.value,
            reason: entry.key,
          );
        }
      },
    );

    test('does not navigate for unsupported jaap requests', () {
      for (final query in [
        "Don't start a chant",
        'जप मत शुरू करना',
        'जप सुरू करू नका',
        'What does the Gayatri mantra mean?',
        'Set 108 jaap repetitions automatically',
        'Clear chanting history',
        'Start a chant and then open Panchang',
      ]) {
        expect(
          LocalVoiceIntentParser.parse(query).action.type,
          'none',
          reason: query,
        );
      }
    });

    test('opens kundali for open kundali chart', () {
      final result = LocalVoiceIntentParser.parse(
        'open kundali chart',
        localeHint: 'en-IN',
      );
      expect(result.action.type, 'open_kundali');
      expect(result.action.type, isNot(equals('open_aarti')));
      expect(result.action.type, isNot(equals('play_aarti')));
      expect(result.action.type, isNot(equals('search_aarti')));
    });

    test('opens kundali for birth chart', () {
      final result = LocalVoiceIntentParser.parse('open birth chart');
      expect(result.action.type, 'open_kundali');
    });

    test('falls back to aarti search for unknown queries', () {
      final result = LocalVoiceIntentParser.parse('सुखकर्ता दुःखहर्ता');
      expect(result.action.type, 'search_aarti');
    });
  });

  test(
    'voice service handles explicit jaap without waiting for the backend',
    () async {
      final result = await VoiceAgentService.processVoiceCommand(
        'namjaap for Ganpati',
        localeHint: 'en-IN',
      );
      expect(result?.action.type, 'start_jaap');
      expect(result?.action.mantraId, 'ganesha');
    },
  );

  test(
    'voice titles resolve against real devotional catalog IDs offline',
    () async {
      final client = MockClient(
        (_) async => throw StateError('Network should be unused'),
      );
      for (final (query, action, id) in [
        ('pasaydan', 'open_aarti', 'pasayadan'),
        ('play Pasaydaan!', 'play_aarti', 'pasayadan'),
        ('shani dev arrti', 'open_aarti', 'shani_aarti'),
        ('शनिदेवाची आरती लावा', 'play_aarti', 'shani_aarti'),
      ]) {
        final result = await VoiceAgentService.processVoiceCommand(
          query,
          localeHint: 'en-IN',
          loadCatalog: () async => kMarathiAartiCatalog,
          client: client,
        );
        expect(result?.action.type, action, reason: query);
        expect(result?.action.aartiId, id, reason: query);
      }
    },
  );

  test(
    'answers app and catalog questions on device and keeps commands actionable',
    () async {
      final offline = MockClient((_) async => throw StateError('offline'));
      for (final (query, locale, type, key, replyText) in [
        (
          'Which languages can I use in this app?',
          'en-IN',
          'answer_app_question',
          'language',
          'Marathi',
        ),
        (
          'How do I choose my Ishta Devta?',
          'en-IN',
          'answer_app_question',
          'ishta_devta',
          'More',
        ),
        (
          'आरतीची आठवण कशी लावायची?',
          'mr-IN',
          'answer_app_question',
          'reminders',
          'काकड',
        ),
        (
          'How do I send a suggestion?',
          'en-IN',
          'answer_app_question',
          'feedback',
          'Submit',
        ),
        (
          'पसायदान बद्दल सांगा',
          'mr-IN',
          'answer_app_question',
          'catalog',
          'ज्ञानेश्वर',
        ),
        (
          'Who sang Pasaydan?',
          'en-IN',
          'answer_app_question',
          'catalog',
          'Lata Mangeshkar',
        ),
        (
          'Who sang Namo Namo by Amit Trivedi?',
          'en-IN',
          'answer_app_question',
          'catalog',
          'Amit Trivedi',
        ),
        (
          'Does Pasaydan have audio?',
          'en-IN',
          'answer_app_question',
          'catalog',
          'recording',
        ),
        ('Take me to the More menu', 'en-IN', 'open_more', null, 'More'),
        (
          'open my daily aarti alerts',
          'en-IN',
          'open_aarti_reminders',
          null,
          'reminder',
        ),
        (
          'How do I change my keyboard language?',
          'en-IN',
          'none',
          null,
          'find',
        ),
        ('Have you already sent my feedback?', 'en-IN', 'none', null, 'find'),
        (
          'Who sang the imaginary Pasaydan remix?',
          'en-IN',
          'none',
          null,
          'find',
        ),
      ]) {
        final result = await VoiceAgentService.processVoiceCommand(
          query,
          localeHint: locale,
          loadCatalog: () async => bundledAartiCatalog,
          client: offline,
        );
        expect(result?.action.type, type, reason: query);
        expect(result?.action.featureKey, key, reason: query);
        expect(result?.responseText, contains(replyText), reason: query);
      }
    },
  );

  test(
    'titles take precedence over a feature word and include video-only recordings',
    () async {
      for (final (query, expected, id) in [
        ('Pratham Tula Vandito', 'open_aarti', 'bhajan_pratham_tula_vandito'),
        ('play Namo Namo by Amit Trivedi', 'open_song_video', 'shiva_yt_01'),
      ]) {
        final result = await VoiceAgentService.processVoiceCommand(
          query,
          localeHint: 'en-IN',
          loadCatalog: () async => bundledAartiCatalog,
        );
        expect(result?.action.type, expected, reason: query);
        expect(
          result?.action.songId ?? result?.action.aartiId,
          id,
          reason: query,
        );
      }
    },
  );

  test(
    'missing titles say not found even if an old backend guesses Mandir',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'action': {'type': 'open_mandir'},
            'response_text': 'Opening Mandir.',
          }),
          200,
        ),
      );
      final result = await VoiceAgentService.processVoiceCommand(
        'play imaginary mandir recording',
        localeHint: 'en-IN',
        loadCatalog: () async => kMarathiAartiCatalog,
        client: client,
      );
      expect(result?.action.type, 'none');
      expect(result?.status, 'not_found');
      expect(result?.responseText, contains('find'));
      expect(
        LocalVoiceIntentParser.parse('open the mandir').action.type,
        'open_mandir',
      );
    },
  );

  testWidgets('voice language selection applies and persists Marathi', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef voiceRef;
    late BuildContext voiceContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [userLanguageCodeProvider.overrideWithValue('en')],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              voiceRef = ref;
              voiceContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    const request = 'chnage the app language to marathi';
    final result = LocalVoiceIntentParser.parse(request, localeHint: 'en-IN');
    expect(result.action.type, 'set_language');
    expect(result.action.languageCode, 'mr');
    expect(
      await VoiceActionDispatcher.execute(
        context: voiceContext,
        ref: voiceRef,
        action: result.action,
        transcript: request,
      ),
      isTrue,
    );
    await tester.pump();
    expect(voiceRef.read(localeProvider), const Locale('mr'));
    expect(await loadUserLanguageCode(), 'mr');
  });

  testWidgets('feedback voice action opens the existing form', (tester) async {
    late WidgetRef voiceRef;
    late BuildContext voiceContext;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                voiceRef = ref;
                voiceContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    const request = 'feedback and suggestions';
    final result = LocalVoiceIntentParser.parse(request, localeHint: 'en-IN');
    expect(result.action.type, 'open_feedback');
    final opened = VoiceActionDispatcher.execute(
      context: voiceContext,
      ref: voiceRef,
      action: result.action,
      transcript: request,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('more-feedback-input')), findsOneWidget);
    Navigator.of(voiceContext).pop();
    await tester.pumpAndSettle();
    expect(await opened, isTrue);
  });

  test(
    'asks for a sign, accepts the reply, and lets the user change subjects',
    () async {
      final first = await VoiceAgentService.processVoiceCommand(
        'rashi sanga',
        localeHint: 'mr-IN',
      );
      expect(first?.status, 'needs_clarification');
      expect(first?.responseText, 'कोणत्या राशीचं भविष्य सांगू?');
      expect(first?.action.rashiId, isNull);
      for (final sign in kAllRashis) {
        final reply = await VoiceAgentService.processVoiceCommand(
          sign.nameMr,
          localeHint: 'mr-IN',
          pendingAction: first?.action.type,
        );
        expect(reply?.action.rashiId, sign.id, reason: sign.nameMr);
      }
      final next = await VoiceAgentService.processVoiceCommand(
        'माझी रास सिंह आहे',
        localeHint: 'mr-IN',
        pendingAction: first?.action.type,
      );
      expect(next?.action.type, 'open_horoscope');
      expect(next?.action.rashiId, 'leo');
      final switched = await VoiceAgentService.processVoiceCommand(
        'open notification',
        localeHint: 'en-IN',
        pendingAction: first?.action.type,
      );
      expect(switched?.action.type, 'open_notifications');
      final reminder = await VoiceAgentService.processVoiceCommand(
        'aarti notification settings',
      );
      expect(reminder?.action.type, 'open_aarti_reminders');
    },
  );

  test(
    'published voice commands resolve on device against the bundled catalog',
    () async {
      final source = await rootBundle.loadString(
        'backend/app/voice_agent/app_help.json',
      );
      final routes = jsonDecode(source)['routes'] as Map<String, dynamic>;
      final offline = MockClient((_) async => http.Response('', 503));
      for (final route in routes.entries) {
        for (final query in (route.value['examples'] as List).cast<String>()) {
          final result = await VoiceAgentService.processVoiceCommand(
            query,
            loadCatalog: () async => bundledAartiCatalog,
            client: offline,
          );
          expect(result?.action.type, route.key, reason: query);
        }
      }
    },
  );

  test('birth-sign conversations compute the Moon sign on device', () async {
    final fixtures =
        jsonDecode(
              await File(
                'test/fixtures/birth_rashi_conversations.json',
              ).readAsString(),
            )
            as List;
    final networkRequests = <Uri>[];
    final offline = MockClient((request) async {
      networkRequests.add(request.url);
      return http.Response('', 503);
    });
    for (final scenario in fixtures) {
      VoiceAgentResult? previous;
      for (final turn in scenario['turns']) {
        final result = (await VoiceAgentService.processVoiceCommand(
          turn[0],
          localeHint: scenario['locale'],
          pendingAction: previous?.status == 'needs_clarification'
              ? previous?.action.type
              : null,
          birthDetails: previous?.birthDetails,
          client: offline,
        ))!;
        final observed =
            result.birthDetails?['step'] ??
            result.action.rashiId ??
            (result.action.type == 'none' ? result.status : result.action.type);
        expect(observed, turn[1], reason: turn[0]);
        if (result.action.rashiId != null) {
          expect(result.responseText, contains(result.action.rashiName!));
          expect(result.birthDetails, isNull);
        }
        previous = result;
      }
    }
    expect(networkRequests, isEmpty);
  });

  test(
    'published help answers and their screen commands work offline',
    () async {
      final data = jsonDecode(
        await rootBundle.loadString('backend/app/voice_agent/app_help.json'),
      );
      final topics = data['topics'] as Map<String, dynamic>;
      final offline = MockClient((_) async => http.Response('', 503));
      for (final entry in topics.entries) {
        final info = entry.value;
        for (final query in info['examples']) {
          final answer = await VoiceAgentService.processVoiceCommand(
            query,
            localeHint: 'mr-IN',
            client: offline,
          );
          expect(answer?.action.featureKey, entry.key, reason: query);
          expect(answer?.responseText, info['reply']['mr'], reason: query);
        }
        if (info['screen_action'] != null) {
          final query = 'Could you bring up ${info['labels']['en']}?';
          final command = await VoiceAgentService.processVoiceCommand(
            query,
            localeHint: 'en-IN',
            client: offline,
          );
          expect(command?.action.type, info['screen_action'], reason: query);
        }
      }
    },
  );

  test('spoken screen requests stay within BhaktiDhara', () async {
    final offline = MockClient((_) async => http.Response('', 503));
    for (final (query, kind) in [
      ('Can we look at the eclipses page?', 'open_grahan'),
      ('Can I change the language used by my work email?', 'none'),
    ]) {
      final result = await VoiceAgentService.processVoiceCommand(
        query,
        localeHint: 'en-IN',
        client: offline,
      );
      expect(result?.action.type, kind, reason: query);
    }
  });

  test('personal jaap answers reflect the current device totals', () async {
    for (final count in [0, 37, 108]) {
      final today = JaapCalendar.dayKey(DateTime.now());
      final progress = JaapProgress(
        lifetimeCount: count + 108,
        dailyLog: {today: count},
        completedDays: {today},
      );
      for (final (query, value, field) in [
        ('How many times did I chant today?', count, 'today_count'),
        ('माझा एकूण जप किती आहे?', count + 108, 'lifetime_count'),
        ('What is my chanting streak?', 1, 'streak'),
      ]) {
        final result = await VoiceAgentService.processVoiceCommand(
          query,
          loadJaapProgress: () async => progress,
        );
        expect(result?.status, 'answered');
        expect(result?.action.field, field);
        expect(result?.responseText, contains(value.toString()));
      }
    }
  });

  testWidgets('open notification shows the home bell inbox', (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef voiceRef;
    late BuildContext voiceContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userLanguageCodeProvider.overrideWithValue('en'),
          announcementsProvider.overrideWith((ref) async => []),
          inAppNotificationsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                voiceContext = context;
                voiceRef = ref;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    const query = 'open notification';
    final result = await tester.runAsync(
      () => VoiceAgentService.processVoiceCommand(query, localeHint: 'en-IN'),
    );
    final opened = VoiceActionDispatcher.execute(
      context: voiceContext,
      ref: voiceRef,
      action: result!.action,
      transcript: query,
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications right now.'), findsOneWidget);
    Navigator.of(voiceContext).pop();
    await tester.pumpAndSettle();
    expect(await opened, isTrue);
  });

  group('VoiceAction JSON Parsing Tests', () {
    test('parses open_horoscope action correctly', () {
      final json = {
        'status': 'action_ready',
        'transcript': 'कुंभ राशीचे आजचे भविष्य दाखवा',
        'locale': 'mr-IN',
        'response_text': 'कुंभ राशीचे आजचे राशीभविष्य उघडत आहे.',
        'action': {
          'type': 'open_horoscope',
          'rashi_id': 'aquarius',
          'rashi_name': 'कुंभ',
          'feature_key': 'horoscope',
        },
        'choices': [],
      };

      final result = VoiceAgentResult.fromJson(json);
      expect(result.status, 'action_ready');
      expect(result.action.type, 'open_horoscope');
      expect(result.action.rashiId, 'aquarius');
      expect(result.action.rashiName, 'कुंभ');
      expect(result.responseText, contains('कुंभ'));
      expect(resolveRashi(result.action.rashiId)?.id, 'aquarius');
    });

    test('parses open_panchang action correctly', () {
      final json = {
        'status': 'action_ready',
        'transcript': 'आज का राहुकाल क्या है?',
        'locale': 'hi-IN',
        'response_text': 'आज का राहुकाल व पंचांग देखा जा रहा है।',
        'action': {
          'type': 'open_panchang',
          'field': 'rahu_kaal',
          'feature_key': 'panchang',
        },
        'choices': [],
      };

      final result = VoiceAgentResult.fromJson(json);
      expect(result.status, 'action_ready');
      expect(result.action.type, 'open_panchang');
      expect(result.action.field, 'rahu_kaal');
    });

    test('parses play_aarti action correctly', () {
      final json = {
        'status': 'action_ready',
        'transcript': 'सुखकर्ता दुःखहर्ता आरती लावा',
        'locale': 'mr-IN',
        'response_text': 'श्री गणेश आरती १ सुरू करत आहे.',
        'action': {
          'type': 'play_aarti',
          'aarti_id': 'ganesh_sukhkarta',
          'title': 'श्री गणेश आरती १ (सुखकर्ता दुःखहर्ता)',
          'has_audio': true,
        },
        'choices': [],
      };

      final result = VoiceAgentResult.fromJson(json);
      expect(result.status, 'action_ready');
      expect(result.action.type, 'play_aarti');
      expect(result.action.aartiId, 'ganesh_sukhkarta');
      expect(result.action.hasAudio, true);
    });
  });
}
