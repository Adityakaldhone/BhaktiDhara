import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nitya_aarti/features/mandir/screens/real_garbhagriha_screen.dart';
import 'package:nitya_aarti/features/voice_agent/data/voice_agent_service.dart';
import 'package:nitya_aarti/features/voice_agent/domain/home_voice_commands.dart';
import 'package:nitya_aarti/features/voice_agent/domain/mandir_voice_commands.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      'mandir_thali_coach_seen': true,
    });
  });

  group('MandirCommand.parse', () {
    test('parses multilingual rituals, status checks, cancellations and unavailable', () {
      expect(MandirCommand.parse('Refill the lamp'), isA<OfferGheeMandir>());
      expect(MandirCommand.parse('माझा दिवा तुपाने भरा'), isA<OfferGheeMandir>());
      expect(MandirCommand.parse('How much ghee is left?'), isA<ReadGheeMandir>());
      expect(MandirCommand.parse('ज्योत शिल्लक'), isA<ReadGheeMandir>());
      expect(MandirCommand.parse('ज्योत'), isA<ExplainMandirTopic>());
      expect(
        (MandirCommand.parse('ज्योत') as ExplainMandirTopic).topic,
        'clarify_jyot',
      );
      expect(
        (MandirCommand.parse('आरती') as ExplainMandirTopic).topic,
        'clarify_aarti',
      );
      expect(
        (MandirCommand.parse('भोग') as ExplainMandirTopic).topic,
        'clarify_food',
      );
      expect(
        (MandirCommand.parse('देवता') as ExplainMandirTopic).topic,
        'clarify_deity',
      );
      expect(
        MandirCommand.parse('शिल्लक', pendingTopic: 'clarify_jyot'),
        isA<ReadGheeMandir>(),
      );
      expect(
        MandirCommand.parse('भरो', pendingTopic: 'clarify_jyot'),
        isA<OfferGheeMandir>(),
      );
      expect(
        MandirCommand.parse('बंद', pendingTopic: 'clarify_aarti'),
        isA<StopAartiMandir>(),
      );
      expect(
        MandirCommand.parse('ठेवा', pendingTopic: 'clarify_food'),
        isA<OfferFoodMandir>(),
      );
      expect(MandirCommand.parse('When will the current ghee run out?'), isA<ReadTimeMandir>());
      expect(MandirCommand.parse('What is my lamp streak?'), isA<ReadStreakMandir>());
      expect(MandirCommand.parse('Ring the temple bells'), isA<RingBellMandir>());
      expect(MandirCommand.parse('शंख वाजवा'), isA<BlowConchMandir>());
      expect(MandirCommand.parse('Offer flowers'), isA<OfferFlowersMandir>());
      expect(MandirCommand.parse('देवासमोर नैवेद्य ठेवा'), isA<OfferFoodMandir>());
      expect(MandirCommand.parse('Start the aarti thali'), isA<StartAartiMandir>());
      expect(MandirCommand.parse('आरतीचे ताट बंद करा'), isA<StopAartiMandir>());
      expect(MandirCommand.parse('Which deity is seated here?'), isA<ReadDeityMandir>());
      expect(MandirCommand.parse('Change deity'), isA<ChangeDeityMandir>());
      expect(MandirCommand.parse('नैवेद्य ठेवू नका'), isA<CancelMandir>());
      expect(MandirCommand.parse('Book a temple ticket'), isA<ExplainMandirTopic>());
      expect(MandirCommand.parse('Open my horoscope'), isNull);
    });

    test('maps every mandir_guide label via fromPrediction', () {
      for (final label in const [
        'offer_ghee',
        'read_ghee',
        'read_time',
        'read_streak',
        'explain_ghee',
        'ring_bell',
        'explain_bell',
        'blow_conch',
        'explain_conch',
        'offer_flowers',
        'explain_flowers',
        'offer_food',
        'read_food',
        'explain_food',
        'start_aarti',
        'stop_aarti',
        'read_aarti',
        'explain_aarti',
        'explain_player',
        'change_deity',
        'read_deity',
        'explain_deity',
        'overview',
        'clarify_jyot',
        'clarify_aarti',
        'clarify_food',
        'clarify_deity',
        'clarify_offering',
        'clarify',
        'cancel',
        'unavailable',
        'other',
      ]) {
        expect(MandirCommand.fromPrediction({'type': label}), isNotNull, reason: label);
      }
    });
  });

  test('VoiceAgentService.predictMandirCommand parses /mandir-control response', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/health')) {
        return http.Response('{"status":"ready"}', 200);
      }
      if (request.url.path.endsWith('/api/v1/voice-agent/mandir-control')) {
        return http.Response(jsonEncode({'action': {'type': 'offer_flowers'}}), 200);
      }
      return http.Response('not found', 404);
    });

    final cmd = await VoiceAgentService.predictMandirCommand(
      'Lay petals before the deity',
      'en-IN',
      client: client,
    );
    expect(cmd, isA<OfferFlowersMandir>());
  });

  testWidgets('RealGarbhagrihaScreen binds Mandir voice handler and cleans up on dispose', (tester) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
    late HomeVoiceBinding binding;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mandirLightRenderingProvider.overrideWith((_) async => true)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              binding = ref.read(homeVoiceBindingProvider);
              return const RealGarbhagrihaScreen();
            },
          ),
        ),
      ),
    );
    for (var t = 0; t < 1600; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final handler = binding.activeMandirHandler?.call();
    expect(handler, isNotNull);

    final gheeReply = handler!('How much ghee is left?', 'en');
    expect(gheeReply, isNotNull);
    expect(gheeReply!.text, contains('% ghee left'));

    final foodBefore = handler('Is naivedya already placed?', 'en', prediction: const ReadFoodMandir());
    expect(foodBefore!.text, contains('No food offering'));

    final offerFood = handler('Offer food', 'en');
    expect(offerFood!.apply, isNotNull);
    offerFood.apply!.call();
    for (var t = 0; t < 1000; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final foodAfter = handler('Is naivedya already placed?', 'en', prediction: const ReadFoodMandir());
    expect(foodAfter!.text, contains('already placed'));

    final deityReply = handler('Which deity is seated here?', 'en');
    expect(deityReply!.text, contains('seated deity'));

    expect(handler('Switch to English', 'en', prediction: const OtherMandir()), isNull);

    for (var t = 0; t < 4000; t += 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(binding.activeMandirHandler, isNull);
    expect(binding.mandirHandler, isNull);
  });
}
