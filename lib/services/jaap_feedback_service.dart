import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/jaap_progress.dart';
import '../domain/entities/jaap_tap_result.dart';

/// Haptics and sounds for the jaap counter, honouring the user's settings.
///
/// Audio players are created lazily so a missing plugin (tests) or a missing
/// asset never breaks counting — haptics still work.
class JaapFeedbackService {
  static const String _bellAsset = 'sounds/ghanti.mp3';
  static const String _shankhAsset = 'sounds/shankh_dhun.mp3';
  static const Duration _shankhLength = Duration(seconds: 4);

  AudioPlayer? _bellPlayer;
  AudioPlayer? _shankhPlayer;
  Timer? _shankhStopTimer;

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
    if (settings.vibrationOn) await HapticFeedback.selectionClick();
  }

  Future<void> _bead(JaapProgress s) async {
    if (s.vibrationOn) await HapticFeedback.lightImpact();
    if (s.tickSoundOn) await SystemSound.play(SystemSoundType.click);
  }

  Future<void> _malaComplete(JaapProgress s) async {
    if (s.vibrationOn) await _pulse(2);
    if (s.bellOn) await _playBell();
  }

  Future<void> _goalComplete(JaapProgress s) async {
    if (s.vibrationOn) await _pulse(3);
    if (s.bellOn) await _playShankh();
  }

  Future<void> _pulse(int times) async {
    for (var i = 0; i < times; i++) {
      await HapticFeedback.heavyImpact();
      if (i < times - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 140));
      }
    }
  }

  Future<void> _playBell() async {
    try {
      final player = _bellPlayer ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(_bellAsset));
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _playShankh() async {
    try {
      final player = _shankhPlayer ??= AudioPlayer();
      _shankhStopTimer?.cancel();
      await player.stop();
      await player.play(AssetSource(_shankhAsset));
      _shankhStopTimer = Timer(_shankhLength, () => player.stop());
    } catch (_) {}
  }

  void dispose() {
    _shankhStopTimer?.cancel();
    _bellPlayer?.dispose();
    _shankhPlayer?.dispose();
  }
}

final jaapFeedbackProvider = Provider<JaapFeedbackService>((ref) {
  final service = JaapFeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
