import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// The sender's photo for the card badge. Kept in app-private storage on this
/// phone only — never uploaded. It leaves the phone only as pixels inside a
/// card the user chooses to share.
class GreetingPhotoStore {
  /// Stored square size; the badge is 76pt, so this is sharp at 3x with margin.
  static const size = 360;
  static const _maxInputBytes = 20 * 1024 * 1024;

  static bool get supported => !kIsWeb;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/status_card_photo.png');
  }

  /// Saves [raw] as a normalised square PNG. False if it isn't a usable image.
  Future<bool> save(Uint8List raw) async {
    final png = await normalize(raw);
    if (png == null) return false;
    try {
      await (await _file()).writeAsBytes(png, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> read() async {
    try {
      final file = await _file();
      return await file.exists() ? await file.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Centre-crops to a square (biased upward, where faces usually are),
  /// downsizes and re-encodes. Re-encoding also drops EXIF data such as GPS.
  static Future<Uint8List?> normalize(Uint8List raw) async {
    if (raw.isEmpty || raw.length > _maxInputBytes) return null;
    ui.Image? source;
    ui.Image? output;
    try {
      final codec = await ui.instantiateImageCodec(raw);
      source = (await codec.getNextFrame()).image;
      codec.dispose();

      final side = math.min(source.width, source.height).toDouble();
      final crop = ui.Rect.fromLTWH(
        (source.width - side) / 2,
        (source.height - side) * 0.3,
        side,
        side,
      );
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        source,
        crop,
        ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      output = await recorder.endRecording().toImage(size, size);
      final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      source?.dispose();
      output?.dispose();
    }
  }
}
