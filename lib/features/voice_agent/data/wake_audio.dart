// Only native builds load the keyword-spotting engine.
export 'wake_audio_stub.dart' if (dart.library.io) 'wake_audio_native.dart';
