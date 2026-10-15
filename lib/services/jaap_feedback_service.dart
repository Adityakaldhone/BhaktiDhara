import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/jaap_progress.dart';
import '../domain/entities/jaap_tap_result.dart';

/// Haptics and sounds for the jaap counter, honouring the user's settings.
///
/// Audio players are created lazily so a missing plugin (tests) or a missing
/// asset never breaks counting — haptics still work.
class JaapFeedbackService {
  static const String _tickAsset = 'sounds/jaap_tick.mp3';
  static const String _bellAsset = 'sounds/ghanti.mp3';
  static const String _shankhAsset = 'sounds/shankh_dhun.mp3';
  static const Duration _shankhLength = Duration(seconds: 4);

  static const MethodChannel _vibration = MethodChannel('bhaktidhara/vibration');

  /// Effects must play alongside chant-along audio; the default context takes
  /// audio focus, which pauses the chant player mid-mala.
  static final AudioContext _effectsContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioPlayer? _tickPlayer;
  AudioPlayer? _bellPlayer;
  AudioPlayer? _shankhPlayer;
  Timer? _shankhStopTimer;
  Future<void>? _tickReady;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Preloads the tick so the first bead isn't delayed by asset decoding.
  void warmUp(JaapProgress settings) {
    if (settings.tickSoundOn) _ensureTick();
  }

  Future<void> onTap(JaapTapResult result, JaapProgress settings) async {
    switch (result.outcome) {
      case JaapTapOutcome.bead:
        await _bead(settings);
      case JaapTapOutcome.malaComplete:
        await _malaComplete(settings);
      case JaapTapOutcome.goalComplete:
        await _goalComplete(settings);
    }
  }

  Future<void> onUndo(JaapProgress settings) async {
    if (settings.vibrationOn) {
      await _vibrate(15, fallback: HapticFeedback.selectionClick);
    }
  }

  Future<void> _bead(JaapProgress s) async {
    if (s.vibrationOn) {
      unawaited(_vibrate(35, amplitude: 180, fallback: HapticFeedback.lightImpact));
    }
    if (s.tickSoundOn) await _playTick();
  }

  Future<void> _malaComplete(JaapProgress s) async {
    if (s.bellOn) unawaited(_playBell());
    if (s.vibrationOn) await _pulse(2);
  }

  Future<void> _goalComplete(JaapProgress s) async {
    if (s.bellOn) unawaited(_playShankh());
    if (s.vibrationOn) await _pulse(3);
  }

  Future<void> _vibrate(
    int ms, {
    int amplitude = -1,
    required Future<void> Function() fallback,
  }) async {
    if (_isAndroid) {
      try {
        final ok = await _vibration.invokeMethod<bool>('vibrate', {
          'duration': ms,
          'amplitude': amplitude,
        });
        if (ok == true) return;
      } catch (_) {}
    }
    await fallback();
  }

  Future<void> _pulse(int times) async {
    if (_isAndroid) {
      final pattern = <int>[0];
      for (var i = 0; i < times; i++) {
        pattern.add(120);
        if (i < times - 1) pattern.add(140);
      }
      try {
        final ok = await _vibration.invokeMethod<bool>('pattern', {
          'pattern': pattern,
        });
        if (ok == true) return;
      } catch (_) {}
    }
    for (var i = 0; i < times; i++) {
      await HapticFeedback.heavyImpact();
      if (i < times - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 140));
      }
    }
  }

  Future<AudioPlayer> _effectPlayer({bool lowLatency = false}) async {
    final player = AudioPlayer();
    await player.setAudioContext(_effectsContext);
    await player.setReleaseMode(ReleaseMode.stop);
    if (lowLatency) await player.setPlayerMode(PlayerMode.lowLatency);
    return player;
  }

  Future<void> _ensureTick() {
    return _tickReady ??= () async {
      final player = await _effectPlayer(lowLatency: true);
      await player.setSource(AssetSource(_tickAsset));
      _tickPlayer = player;
    }();
  }

  Future<void> _playTick() async {
    try {
      await _ensureTick();
      final player = _tickPlayer!;
      await player.stop();
      await player.resume();
    } catch (_) {
      _tickReady = null;
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _playBell() async {
    try {
      final player = _bellPlayer ??= await _effectPlayer();
      await player.stop();
      await player.play(AssetSource(_bellAsset));
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _playShankh() async {
    try {
      final player = _shankhPlayer ??= await _effectPlayer();
      _shankhStopTimer?.cancel();
      await player.stop();
      await player.play(AssetSource(_shankhAsset));
      _shankhStopTimer = Timer(_shankhLength, () => player.stop());
    } catch (_) {}
  }

  void dispose() {
    _shankhStopTimer?.cancel();
    _tickPlayer?.dispose();
    _bellPlayer?.dispose();
    _shankhPlayer?.dispose();
  }
}

final jaapFeedbackProvider = Provider<JaapFeedbackService>((ref) {
  final service = JaapFeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
