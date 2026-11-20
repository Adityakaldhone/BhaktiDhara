import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Captures a [RepaintBoundary] and exports it as PNG (gallery) or PDF.
class ChartExportService {
  ChartExportService._();

  static Future<Uint8List?> capturePng(
    GlobalKey key, {
    double pixelRatio = 3,
  }) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    // Wait one frame so layout/paint are settled before capture.
    await Future<void>.delayed(Duration.zero);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  /// Returns `true` when the image was written to the BhaktiDhara album.
  static Future<bool> saveToGallery(
    GlobalKey key, {
    required String fileName,
  }) async {
    if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
      return false;
    }
    final bytes = await capturePng(key);
    if (bytes == null || bytes.isEmpty) return false;
    await Gal.putImageBytes(
      bytes,
      album: 'BhaktiDhara',
      name: fileName,
    );
    return true;
  }

  /// Captures the chart as a single-page PDF and opens the system share sheet
  /// so the devotee can save it to Files / Drive / WhatsApp.
  static Future<bool> saveAsPdf(
    GlobalKey key, {
    required String fileName,
  }) async {
    final pngBytes = await capturePng(key);
    if (pngBytes == null || pngBytes.isEmpty) return false;

    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final imgW = frame.image.width.toDouble();
    final imgH = frame.image.height.toDouble();
    frame.image.dispose();

    final pageFormat = PdfPageFormat(
      imgW,
      imgH,
      marginAll: 0,
    );

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(
          child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.contain),
        ),
      ),
    );

    final pdfBytes = await doc.save();
    final safe = fileName.replaceAll(RegExp(r'[^\w\u0900-\u097F.-]+'), '_');
    final name = safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(pdfBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf', name: name)],
        subject: name,
      ),
    );
    return true;
  }
}
