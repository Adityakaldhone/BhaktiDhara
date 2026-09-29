import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Thin wrapper around [audioplayers] for ghanti (bell) and shankh (conch)
/// sound effects.
///
/// Both methods always trigger [HapticFeedback.heavyImpact] so the
/// tactile experience works even when audio assets are not yet bundled.
///
/// To activate real audio:
///   1. Place ghanti.mp3 and shankh.mp3 under assets/sounds/
///   2. Uncomment the assets/sounds/ entries in pubspec.yaml
class AudioService {
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _conchPlayer = AudioPlayer();

  /// Plays the temple bell sound. Falls back to haptics if asset is missing.
  Future<void> playBell() async {
    await HapticFeedback.heavyImpact();
    try {
      await _bellPlayer.stop();
      await _bellPlayer.play(AssetSource('sounds/ghanti.mp3'));
    } catch (_) {
      // Audio asset not yet bundled — haptic feedback only (expected in demo)
    }
  }

  /// Plays the conch shell sound. Falls back to haptics if asset is missing.
  Future<void> playConch() async {
    await HapticFeedback.heavyImpact();
    try {
      await _conchPlayer.stop();
      await _conchPlayer.play(AssetSource('sounds/shankh_dhun.mp3'));
    } catch (_) {
      try {
        await _conchPlayer.play(AssetSource('sounds/shankh.mp3'));
      } catch (_) {
        // Audio asset not yet bundled — haptic feedback only
      }
    }
  }

  /// Release underlying [AudioPlayer] resources.
  void dispose() {
    _bellPlayer.dispose();
    _conchPlayer.dispose();
  }
}
