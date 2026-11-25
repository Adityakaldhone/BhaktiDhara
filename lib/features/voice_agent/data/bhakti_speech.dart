import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import 'voice_agent_service.dart';

/// Live speech for Bhakti: prefers neural backend TTS, falls back to on-device TTS.
/// Never relies on canned greeting MP3 as the primary path.
class BhaktiSpeech {
  BhaktiSpeech._();

  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static bool _ttsReady = false;
  static StreamSubscription<void>? _completeSub;

  static Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.setVolume(1.0);
    // ~0.48 is closer to natural conversation than the slower default feel.
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);
    _ttsReady = true;
  }

  static Future<void> stop() async {
    try {
      await _completeSub?.cancel();
      _completeSub = null;
      await _player.stop();
      await _tts.stop();
    } catch (_) {}
  }

  /// Speaks [text] and completes when playback finishes (or after a short timeout).
  static Future<void> speak(
    String text, {
    required String localeHint,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    await stop();

    final neuralOk = await _speakNeural(clean, localeHint);
    if (neuralOk) return;

    await _speakOnDevice(clean, localeHint);
  }

  static Future<bool> _speakNeural(String text, String localeHint) async {
    for (final base in VoiceAgentService.candidateUrls) {
      try {
        final uri = Uri.parse(
          '$base/api/v1/voice-agent/tts'
          '?text=${Uri.encodeComponent(text)}'
          '&locale=${Uri.encodeComponent(localeHint)}',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          continue;
        }
        final bytes = Uint8List.fromList(response.bodyBytes);
        final done = Completer<void>();
        await _completeSub?.cancel();
        _completeSub = _player.onPlayerComplete.listen((_) {
          if (!done.isCompleted) done.complete();
        });
        await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
        await done.future.timeout(
          Duration(milliseconds: (text.length * 90).clamp(2500, 12000)),
          onTimeout: () {},
        );
        return true;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Bhakti neural TTS via $base failed: $e');
        }
      }
    }
    return false;
  }

  static Future<void> _speakOnDevice(String text, String localeHint) async {
    await _ensureTts();
    final lang = localeHint.startsWith('hi')
        ? 'hi-IN'
        : localeHint.startsWith('en')
            ? 'en-IN'
            : 'mr-IN';
    try {
      await _tts.setLanguage(lang);
    } catch (_) {
      try {
        await _tts.setLanguage(localeHint.startsWith('en') ? 'en-US' : 'hi-IN');
      } catch (_) {}
    }

    final done = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!done.isCompleted) done.complete();
    });
    _tts.setCancelHandler(() {
      if (!done.isCompleted) done.complete();
    });
    _tts.setErrorHandler((_) {
      if (!done.isCompleted) done.complete();
    });

    await _tts.speak(text);
    await done.future.timeout(
      Duration(milliseconds: (text.length * 90).clamp(2500, 12000)),
      onTimeout: () {},
    );
  }
}
