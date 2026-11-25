import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as kws;

class WakeAudio {
  static bool get supported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _mic;
  SendPort? _worker;
  Future<void>? _exit;
  bool _stopping = false;

  Future<bool> permission({required bool request}) async =>
      (_recorder ??= AudioRecorder()).hasPermission(request: request);

  Future<void> start(void Function() wake, void Function() interrupted) async {
    _stopping = false;
    final cache = await getApplicationCacheDirectory();
    final dir = await Directory(
      '${cache.path}/bhakti-wake-v1',
    ).create(recursive: true);
    for (final name in [
      'encoder.onnx',
      'decoder.onnx',
      'joiner.onnx',
      'tokens.txt',
      'keywords.txt',
    ]) {
      final file = File('${dir.path}/$name');
      if (await file.exists()) continue;
      final bytes = await rootBundle.load('assets/bhakti_wake/$name');
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      await tmp.rename(file.path);
    }
    final events = ReceivePort();
    final ready = Completer<SendPort>();
    final exited = Completer<void>();
    events.listen((event) {
      if (event is SendPort) {
        ready.complete(event);
      } else if (event == 'wake') {
        if (!_stopping) wake();
      } else if (event == null) {
        if (!ready.isCompleted) {
          ready.completeError(StateError('Wake engine exited'));
        } else if (!_stopping) {
          interrupted();
        }
        events.close();
        exited.complete();
      } else if (event is List && !ready.isCompleted) {
        ready.completeError(StateError(event.first.toString()));
      }
    });
    try {
      await Isolate.spawn(
        _decode,
        (events.sendPort, dir.path),
        onError: events.sendPort,
        onExit: events.sendPort,
      );
    } catch (_) {
      events.close();
      rethrow;
    }
    _exit = exited.future;
    _worker = await ready.future;
    final audio = await (_recorder ??= AudioRecorder()).startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        streamBufferSize: 3200,
        androidConfig: AndroidRecordConfig(manageBluetooth: false),
        iosConfig: IosRecordConfig(
          categoryOptions: [
            IosAudioCategoryOption.mixWithOthers,
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
          ],
        ),
      ),
    );
    _mic = audio.listen(
      (bytes) => _worker?.send(bytes),
      onError: (Object _) {
        if (!_stopping) interrupted();
      },
      onDone: () {
        if (!_stopping) interrupted();
      },
    );
  }

  Future<void> stop() async {
    _stopping = true;
    _worker?.send(null);
    _worker = null;
    try {
      await _mic?.cancel();
      _mic = null;
    } finally {
      final recorder = _recorder;
      _recorder = null;
      try {
        await recorder?.dispose();
      } finally {
        await _exit;
        _exit = null;
      }
    }
  }

  static Future<void> _decode((SendPort, String) args) async {
    final (events, dir) = args;
    kws.initBindings();
    final engine = kws.KeywordSpotter(
      kws.KeywordSpotterConfig(
        model: kws.OnlineModelConfig(
          transducer: kws.OnlineTransducerModelConfig(
            encoder: '$dir/encoder.onnx',
            decoder: '$dir/decoder.onnx',
            joiner: '$dir/joiner.onnx',
          ),
          tokens: '$dir/tokens.txt',
          numThreads: 1,
          debug: false,
        ),
        keywordsFile: '$dir/keywords.txt',
        maxActivePaths: 8,
        keywordsScore: .9,
        keywordsThreshold: .22,
      ),
    );
    final input = ReceivePort();
    final stream = engine.createStream();
    var detected = false;
    try {
      events.send(input.sendPort);
      await for (final bytes in input) {
        if (bytes == null) break;
        if (detected) continue;
        final pcm = ByteData.sublistView(bytes as Uint8List);
        final samples = Float32List(pcm.lengthInBytes ~/ 2);
        for (var i = 0; i < samples.length; i++) {
          samples[i] = pcm.getInt16(i * 2, Endian.little) / 32768;
        }
        stream.acceptWaveform(samples: samples, sampleRate: 16000);
        while (engine.isReady(stream)) {
          engine.decode(stream);
          final keyword = engine.getResult(stream).keyword;
          if (keyword == 'BHAKTI') {
            detected = true;
            events.send('wake');
            break;
          }
          // Similar-sounding phrases compete during decoding and never wake the app.
          if (keyword.isNotEmpty) engine.reset(stream);
        }
      }
    } finally {
      input.close();
      stream.free();
      engine.free();
    }
  }
}
