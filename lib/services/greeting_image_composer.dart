import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Where the user's photo circle sits on a greeting image, as fractions of
/// the image width. Shared by the on-screen preview and the exported file so
/// what the user sees is exactly what gets sent.
class GreetingPhotoLayout {
  static const diameter = 0.22;
  static const margin = 0.04;
  static const ring = 0.012;

  static Rect circle(Size image) {
    final d = image.width * diameter;
    final m = image.width * margin;
    return Rect.fromLTWH(m, image.height - m - d, d, d);
  }
}

class GreetingExport {
  final Uint8List bytes;
  final String mimeType;

  const GreetingExport(this.bytes, this.mimeType);

  String get extension => mimeType == 'image/png' ? 'png' : 'jpg';
}

class GreetingImageComposer {
  GreetingImageComposer._();

  /// The HD file, from the disk cache when the viewer already loaded it.
  static Future<Uint8List> downloadHd(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    return file.readAsBytes();
  }

  /// The HD image as downloaded, or re-drawn with [photo] in a circle at the
  /// bottom-left when the user has one.
  static Future<GreetingExport> build(String hdUrl, {Uint8List? photo}) async {
    final hd = await downloadHd(hdUrl);
    if (photo == null) return GreetingExport(hd, 'image/jpeg');
    return GreetingExport(await withPhoto(hd, photo), 'image/png');
  }

  static Future<Uint8List> withPhoto(Uint8List base, Uint8List photo) async {
    ui.Image? baseImage;
    ui.Image? photoImage;
    ui.Image? output;
    try {
      baseImage = await _decode(base);
      photoImage = await _decode(photo);
      final size = Size(baseImage.width.toDouble(), baseImage.height.toDouble());
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(baseImage, Offset.zero, ui.Paint()..filterQuality = ui.FilterQuality.high);

      final circle = GreetingPhotoLayout.circle(size);
      final ringWidth = size.width * GreetingPhotoLayout.ring;
      canvas.drawCircle(
        circle.center.translate(0, ringWidth * 0.6),
        circle.width / 2 + ringWidth,
        ui.Paint()
          ..color = const ui.Color(0x55000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, ringWidth * 1.5),
      );
      canvas.drawCircle(circle.center, circle.width / 2 + ringWidth, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      canvas.save();
      canvas.clipPath(ui.Path()..addOval(circle));
      canvas.drawImageRect(
        photoImage,
        Rect.fromLTWH(0, 0, photoImage.width.toDouble(), photoImage.height.toDouble()),
        circle,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      canvas.restore();

      output = await recorder.endRecording().toImage(baseImage.width, baseImage.height);
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      baseImage?.dispose();
      photoImage?.dispose();
      output?.dispose();
    }
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}
