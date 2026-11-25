import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nitya_aarti/features/voice_agent/presentation/widgets/bhakti_wake_host.dart';
import 'package:nitya_aarti/features/voice_agent/presentation/widgets/bhakti_voice_modal.dart';
import 'package:nitya_aarti/presentation/providers/locale_provider.dart';
import 'package:nitya_aarti/features/voice_agent/data/bhakti_wake_controller.dart';
import 'package:nitya_aarti/features/voice_agent/data/wake_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Audio implements WakeAudio {
  bool granted = true;
  Completer<void>? starting;
  final events = <String>[];
  void Function()? trigger;

  @override
  Future<bool> permission({required bool request}) async => granted;

  @override
  Future<void> start(void Function() wake, void Function() interrupted) async {
    events.add('start');
    trigger = wake;
    await starting?.future;
  }

  @override
  Future<void> stop() async => events.add('stop');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'a wake detection opens one sheet and starts command recognition',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'bhakti_foreground_wake_enabled': true,
      });
      final audio = _Audio();
      final controller = BhaktiWakeController(audio);
      final navigator = GlobalKey<NavigatorState>();
      final speechCalls = <String>[];
      const speech = MethodChannel('plugin.csdcorp.com/speech_to_text');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(speech, (call) async {
        speechCalls.add(call.method);
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(speech, null));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bhaktiWakeProvider.overrideWith((_) => controller),
            localeProvider.overrideWith((_) => const Locale('en')),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            builder: (_, child) =>
                BhaktiWakeHost(navigator: navigator, child: child!),
            home: const Scaffold(),
          ),
        ),
      );
      await tester.pump();
      expect(audio.events, ['start']);
      audio.trigger!();
      audio.trigger!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(BhaktiVoiceModal), findsOneWidget);
      expect(speechCalls.where((call) => call == 'listen'), hasLength(1));
      expect(audio.events, ['start', 'stop']);
      await tester.pump(const Duration(milliseconds: 400));
      await messenger.handlePlatformMessage(
        speech.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('notifyStatus', 'doneNoResult'),
        ),
        (_) {},
      );
      await tester.pump();
      expect(find.text('Ready'), findsOneWidget);
      expect(audio.events.last, 'start');
      audio.trigger!();
      await tester.pump();
      expect(find.byType(BhaktiVoiceModal), findsOneWidget);
      expect(speechCalls.where((call) => call == 'listen'), hasLength(2));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.byType(BhaktiVoiceModal), findsNothing);
      expect(audio.events, ['start', 'stop', 'start', 'stop', 'start']);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    },
  );

  test('wake, command handoff, dismiss, background and disable', () async {
    SharedPreferences.setMockInitialValues({});
    final audio = _Audio();
    final controller = BhaktiWakeController(audio);
    var wakes = 0;
    controller.onWake = () {
      wakes++;
      unawaited(controller.setModal(true));
    };
    controller.foreground(true);
    await controller.restore();
    expect(audio.events, isEmpty);
    expect(await controller.setEnabled(true), isTrue);
    audio.trigger!();
    audio.trigger!();
    await controller.setModal(true);
    expect(wakes, 1);
    expect(audio.events, ['start', 'stop']);
    await controller.setModal(false);
    expect(audio.events.last, 'start');
    controller.foreground(false);
    audio.trigger!();
    await controller.setModal(false);
    expect(wakes, 1);
    expect(audio.events.last, 'stop');
    controller.foreground(true);
    await controller.setModal(false);
    expect(audio.events.last, 'start');
    expect(await controller.setEnabled(false), isTrue);
    expect(audio.events.last, 'stop');
    controller.dispose();
  });

  test(
    'revoked permission and an interrupted start never open the modal',
    () async {
      SharedPreferences.setMockInitialValues({
        'bhakti_foreground_wake_enabled': true,
      });
      final audio = _Audio()..granted = false;
      final controller = BhaktiWakeController(audio);
      controller.onWake = () => fail('unexpected activation');
      controller.foreground(true);
      await controller.restore();
      expect(audio.events, isEmpty);
      audio.granted = true;
      audio.starting = Completer();
      controller.foreground(true);
      await Future<void>.delayed(Duration.zero);
      expect(audio.events, ['start']);
      controller.foreground(false);
      audio.trigger!();
      audio.starting!.complete();
      await controller.setModal(false);
      expect(audio.events, ['start', 'stop']);
      controller.dispose();
    },
  );
}
