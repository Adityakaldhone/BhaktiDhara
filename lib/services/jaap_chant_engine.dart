import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays a single-repetition mantra clip [repetitions] times in a row and
/// reports each completed repetition, so beads can be credited one by one.
abstract class ChantAudioEngine {
  Future<void> start({
    required String asset,
    required int repetitions,
    required void Function() onRepetition,
    required void Function() onFinished,
  });

  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  void dispose();
}

class AudioplayersChantEngine implements ChantAudioEngine {
  /// Breathing space between repetitions so the chant has a natural rhythm.
  static const Duration gap = Duration(milliseconds: 500);

  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;
  Timer? _gapTimer;
  int _remaining = 0;
  bool _paused = false;
  bool _inGap = false;
  void Function()? _onRepetition;
  void Function()? _onFinished;

  @override
  Future<void> start({
    required String asset,
    required int repetitions,
    required void Function() onRepetition,
    required void Function() onFinished,
  }) async {
    await stop();
    _remaining = repetitions;
    _onRepetition = onRepetition;
    _onFinished = onFinished;
    _paused = false;

    final player = _player ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    _completeSub = player.onPlayerComplete.listen((_) => _handleComplete());
    await player.setSource(AssetSource(asset));
    await player.resume();
  }

  void _handleComplete() {
    _onRepetition?.call();
    _remaining--;
    if (_remaining <= 0) {
      _completeSub?.cancel();
      _completeSub = null;
      _onFinished?.call();
      return;
    }
    _inGap = true;
    _gapTimer = Timer(gap, () {
      _inGap = false;
      if (!_paused) _player?.resume();
    });
  }

  @override
  Future<void> pause() async {
    _paused = true;
    if (!_inGap) await _player?.pause();
  }

  @override
  Future<void> resume() async {
    _paused = false;
    if (_inGap) {
      if (!(_gapTimer?.isActive ?? false)) {
        _inGap = false;
        await _player?.resume();
      }
    } else {
      await _player?.resume();
    }
  }

  @override
  Future<void> stop() async {
    _gapTimer?.cancel();
    _inGap = false;
    await _completeSub?.cancel();
    _completeSub = null;
    _remaining = 0;
    await _player?.stop();
  }

  @override
  void dispose() {
    _gapTimer?.cancel();
    _completeSub?.cancel();
    _player?.dispose();
  }
}

final chantAudioEngineProvider = Provider<ChantAudioEngine>((ref) {
  final engine = AudioplayersChantEngine();
  ref.onDispose(engine.dispose);
  return engine;
});
