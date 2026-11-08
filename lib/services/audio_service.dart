import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ghanti (bell) and shankh (conch) sounds for the aarti altar.
///
/// Each sound is a toggle: the first tap starts it, a second tap while it is
/// still sounding stops it. [bellPlaying] / [conchPlaying] report the state
/// and fall back to `false` when the sound finishes on its own.
///
/// The players mix with other audio instead of taking audio focus, so the
/// aarti video keeps playing underneath.
class AudioService {
  static const String _bellAsset = 'sounds/aarti_ghanti.mp3';
  static const String _conchAsset = 'sounds/shankh_dhun.mp3';

  static final AudioContext _mixContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final ValueNotifier<bool> bellPlaying = ValueNotifier(false);
  final ValueNotifier<bool> conchPlaying = ValueNotifier(false);

  Future<AudioPlayer>? _bellPlayer;
  Future<AudioPlayer>? _conchPlayer;
  bool _disposed = false;

  Future<void> toggleBell() =>
      _toggle(_bellPlayer ??= _createPlayer(bellPlaying), bellPlaying, _bellAsset);

  Future<void> toggleConch() => _toggle(
      _conchPlayer ??= _createPlayer(conchPlaying), conchPlaying, _conchAsset);

  Future<AudioPlayer> _createPlayer(ValueNotifier<bool> state) async {
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) {
      if (!_disposed) state.value = false;
    });
    try {
      await player.setAudioContext(_mixContext);
    } catch (_) {}
    return player;
  }

  Future<void> _toggle(
    Future<AudioPlayer> playerFuture,
    ValueNotifier<bool> state,
    String asset,
  ) async {
    HapticFeedback.heavyImpact();
    final shouldPlay = !state.value;
    state.value = shouldPlay;
    try {
      final player = await playerFuture;
      if (shouldPlay) {
        await player.stop();
        await player.play(AssetSource(asset));
      } else {
        await player.stop();
      }
    } catch (_) {
      if (!_disposed) state.value = false;
    }
  }

  void dispose() {
    _disposed = true;
    _bellPlayer?.then((p) => p.dispose());
    _conchPlayer?.then((p) => p.dispose());
    bellPlaying.dispose();
    conchPlaying.dispose();
  }
}
