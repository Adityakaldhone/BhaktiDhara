import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/datasources/greeting_content.dart';
import '../data/repositories/greeting_photo_store.dart';
import '../domain/entities/greeting_card.dart';
import '../presentation/widgets/greeting/card_canvas.dart';

/// Turns a [GreetingCardData] into a 1080x1920 PNG entirely on the phone —
/// no server, no network, no cost per card.
class CardRenderer {
  CardRenderer._();

  static const pixelRatio = 3.0;
  static const _logoAsset = 'assets/app_logo/logo.png';

  static final Map<String, Future<ui.Image>> _imageCache = {};
  static final Map<String, Uint8List> _pngCache = {};
  static final Set<String> _smallAssets = {};
  static int? _photoStamp;
  static Future<ui.Image?>? _photo;

  static Future<ui.Image> _loadImage(String asset, int targetWidth) {
    // Only large deity art is evicted; the logo and decorations are tiny.
    final isLarge = targetWidth >= 720;
    if (!isLarge) _smallAssets.add(asset);
    if (isLarge && !_imageCache.containsKey(asset)) {
      final large = _imageCache.keys.where((k) => !_smallAssets.contains(k)).toList();
      if (large.length >= 4) _imageCache.remove(large.first);
    }
    return _imageCache.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
  }

  static Future<ui.Image?> _loadPhoto(int stamp) {
    if (_photoStamp != stamp || _photo == null) {
      _photoStamp = stamp;
      _photo = () async {
        try {
          final bytes = await GreetingPhotoStore().read();
          if (bytes == null) return null;
          final codec = await ui.instantiateImageCodec(bytes, targetWidth: 270);
          final frame = await codec.getNextFrame();
          codec.dispose();
          return frame.image;
        } catch (_) {
          return null;
        }
      }();
    }
    return _photo!;
  }

  /// Decoded deity + logo for a card. Deity art ships at 1–2.7 MB, so it is
  /// downscaled to 720px wide (sharp at 3x inside a 196pt arch).
  static Future<CardImages> loadImages(String deityId, {int? photoStamp}) async {
    final deity = GreetingContent.deity(deityId);
    final photo = photoStamp == null ? null : await _loadPhoto(photoStamp);
    try {
      final results = await Future.wait([
        _loadImage(deity.asset, 720),
        _loadImage(_logoAsset, 96),
        _loadImage('assets/aarti_screen/deepak.png', 240),
        _loadImage('assets/aarti_screen/pushpa.png', 120),
        _loadImage('assets/decorations/bell.png', 120),
        _loadImage('assets/aarti_screen/shankh.png', 160),
      ]);
      return CardImages(
        deity: results[0],
        deityIsCutout: deity.isCutout,
        logo: results[1],
        diya: results[2],
        flower: results[3],
        bell: results[4],
        shankh: results[5],
        photo: photo,
      );
    } catch (_) {
      _imageCache.remove(deity.asset);
      return CardImages(photo: photo);
    }
  }

  static Future<void> warmUpFonts() async {
    try {
      GoogleFonts.yatraOne();
      GoogleFonts.tiroDevanagariMarathi();
      for (final weight in [FontWeight.w400, FontWeight.w600, FontWeight.w700, FontWeight.w800]) {
        GoogleFonts.mukta(fontWeight: weight);
      }
      await GoogleFonts.pendingFonts();
    } catch (_) {
      // A missing font falls back to the system Devanagari font; still shareable.
    }
  }

  static Future<Uint8List> renderPng(GreetingCardData data) async {
    final cached = _pngCache[data.cacheKey];
    if (cached != null) return cached;

    await warmUpFonts();
    final images = await loadImages(data.deityId, photoStamp: data.photoStamp);
    final bytes = await _renderWidget(GreetingCardCanvas(data: data, images: images));
    if (_pngCache.length > 6) _pngCache.remove(_pngCache.keys.first);
    _pngCache[data.cacheKey] = bytes;
    return bytes;
  }

  static Future<Uint8List> _renderWidget(Widget widget) async {
    const size = GreetingCardCanvas.logicalSize;
    final boundary = RenderRepaintBoundary();
    final view = WidgetsBinding.instance.platformDispatcher.implicitView ??
        WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: 1,
      ),
    );
    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner.buildScope(root);
      buildOwner.finalizeTree();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData!.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
          .attachToRenderTree(buildOwner, root);
      buildOwner.finalizeTree();
      pipelineOwner.rootNode = null;
    }
  }
}
