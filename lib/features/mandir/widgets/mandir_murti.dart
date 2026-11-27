import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/bhakti_deity.dart';

enum Abhishek { water, milk }

/// Measured normalized structure of a deity cutout so Jalabhishek & Dugdhabhishek
/// adapt to every deity's height, width, shoulder contour, and base.
class _MurtiProfile {
  const _MurtiProfile({
    this.crown = const Offset(.5, .06),
    this.bottomY = .97,
    this.slices = const [
      (.40, .60),
      (.30, .70),
      (.24, .76),
      (.25, .75),
      (.26, .74),
      (.24, .76),
      (.22, .78),
      (.20, .80),
    ],
  });

  final Offset crown;
  final double bottomY;
  final List<(double left, double right)> slices;

  (double left, double right) boundsAt(double u) {
    final clamped = u.clamp(0.0, 1.0);
    final scaled = clamped * (slices.length - 1);
    final i0 = scaled.floor();
    final i1 = math.min(slices.length - 1, i0 + 1);
    final f = scaled - i0;
    final l = ui.lerpDouble(slices[i0].$1, slices[i1].$1, f)!;
    final r = ui.lerpDouble(slices[i0].$2, slices[i1].$2, f)!;
    return (l, r);
  }
}

/// Uses the same decoded portrait for darshan, structural measurement, and the liquid mask.
class MandirMurti extends StatefulWidget {
  const MandirMurti({
    super.key,
    required this.deity,
    required this.decodeWidth,
    required this.progress,
    required this.liquid,
    this.lightRendering = false,
  });

  final BhaktiDeity deity;
  final int decodeWidth;
  final Animation<double> progress;
  final Abhishek liquid;
  final bool lightRendering;

  @override
  State<MandirMurti> createState() => _MandirMurtiState();
}

class _MandirMurtiState extends State<MandirMurti> {
  static final Map<String, _MurtiProfile> _profileCache = {};

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _frame;
  _MurtiProfile _profile = const _MurtiProfile();

  String get _cacheKey => '${widget.deity.imageAsset}|${widget.deity.imageUrl}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(MandirMurti old) {
    super.didUpdateWidget(old);
    if (old.decodeWidth != widget.decodeWidth ||
        old.deity.imageAsset != widget.deity.imageAsset ||
        old.deity.imageUrl != widget.deity.imageUrl) {
      _resolve();
    }
  }

  void _resolve({bool fallback = false}) {
    final url = widget.deity.imageUrl.trim();
    final remote = !fallback && url.isNotEmpty;
    final ImageProvider provider = remote ? CachedNetworkImageProvider(url) : AssetImage(widget.deity.imageAsset);
    final next = ResizeImage.resizeIfNeeded(
      widget.decodeWidth,
      null,
      provider,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == next.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = next;
    _listener = ImageStreamListener(
      (frame, _) {
        final old = _frame;
        final cached = _profileCache[_cacheKey];
        setState(() {
          _frame = frame;
          _profile = cached ?? const _MurtiProfile();
        });
        old?.dispose();
        if (cached == null) _measureProfile(frame);
      },
      onError: (Object error, StackTrace? stack) {
        if (mounted && remote) _resolve(fallback: true);
      },
    );
    next.addListener(_listener!);
  }

  Future<void> _measureProfile(ImageInfo frame) async {
    // Sample a 64x64 thumbnail once per deity so height, crown offset, shoulder
    // width, and lotus base adapt dynamically for every murti structure.
    final image = frame.image;
    const side = 64;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, 64, 64),
      Paint()..filterQuality = FilterQuality.low,
    );
    final picture = recorder.endRecording();
    final thumb = await picture.toImage(side, side);
    picture.dispose();
    final bytes = await thumb.toByteData(format: ui.ImageByteFormat.rawRgba);
    thumb.dispose();
    if (!mounted || _frame != frame || bytes == null) return;

    bool solid(int x, int y) => bytes.getUint8((y * side + x) * 4 + 3) > 96;

    var minX = side, maxX = -1, minY = side, maxY = -1;
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        if (solid(x, y)) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }
    if (maxX < minX || maxY <= minY) return;

    final middle = (minX + maxX) ~/ 2;
    final radius = math.max(2, (maxX - minX) ~/ 5);
    var crownX = (middle + 0.5) / side;
    var crownY = minY / side;
    outer:
    for (var y = minY; y <= maxY; y++) {
      for (var d = 0; d <= radius; d++) {
        for (final x in [middle - d, middle + d]) {
          if (x >= 0 && x < side && solid(x, y)) {
            crownX = (x + 0.5) / side;
            crownY = y / side;
            break outer;
          }
        }
      }
    }

    const sliceCount = 8;
    final spanY = math.max(1, maxY - (crownY * side).round());
    final slices = <(double, double)>[];
    for (var s = 0; s < sliceCount; s++) {
      final yStart = ((crownY * side).round() + (spanY * s) ~/ sliceCount).clamp(0, side - 1);
      final yEnd = ((crownY * side).round() + (spanY * (s + 1)) ~/ sliceCount).clamp(yStart, side - 1);
      var bandLeft = side;
      var bandRight = -1;
      for (var y = yStart; y <= yEnd; y++) {
        for (var x = minX; x <= maxX; x++) {
          if (solid(x, y)) {
            bandLeft = math.min(bandLeft, x);
            bandRight = math.max(bandRight, x);
          }
        }
      }
      if (bandRight < bandLeft) {
        slices.add(((minX + 0.5) / side, (maxX + 0.5) / side));
      } else {
        slices.add((bandLeft / side, (bandRight + 1) / side));
      }
    }

    final measured = _MurtiProfile(
      crown: Offset(crownX.clamp(0.25, 0.75), crownY.clamp(0.02, 0.55)),
      bottomY: ((maxY + 1) / side).clamp(0.65, 1.0),
      slices: slices,
    );
    _profileCache[_cacheKey] = measured;
    setState(() => _profile = measured);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    if (frame == null) return const SizedBox.expand();
    return CustomPaint(
      size: Size.infinite,
      painter: _MurtiPainter(frame.image, _profile, widget.progress, widget.liquid, widget.lightRendering),
    );
  }
}

class _MurtiPainter extends CustomPainter {
  _MurtiPainter(this.image, this.profile, this.progress, this.liquid, this.lightRendering) : super(repaint: progress);

  final ui.Image image;
  final _MurtiProfile profile;
  final Animation<double> progress;
  final Abhishek liquid;
  final bool lightRendering;
  Rect? _shaderRect;
  ui.ImageShader? _silhouette;

  ui.ImageShader _maskAt(Rect rect) {
    if (_shaderRect != rect) {
      final transform = Matrix4.diagonal3Values(rect.width / image.width, rect.height / image.height, 1)
        ..setTranslationRaw(rect.left, rect.top, 0);
      _silhouette = ui.ImageShader(
        image,
        TileMode.decal,
        TileMode.decal,
        transform.storage,
        filterQuality: FilterQuality.low,
      );
      _shaderRect = rect;
    }
    return _silhouette!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final source = Size(image.width.toDouble(), image.height.toDouble());
    final fit = applyBoxFit(BoxFit.contain, source, size);
    final rect = Alignment.bottomCenter.inscribe(fit.destination, Offset.zero & size);
    final src = Offset.zero & source;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final t = progress.value;
    if (t <= 0 || t >= 1) {
      canvas.drawImageRect(image, src, rect, paint);
      return;
    }

    final contact = rect.topLeft + Offset(profile.crown.dx * rect.width, profile.crown.dy * rect.height);
    final baseY = rect.top + profile.bottomY * rect.height;
    final reach = math.max(20.0, baseY - contact.dy);
    final fade = math.min(1.0, math.min(t * 9, (1 - t) * 7));
    final milk = liquid == Abhishek.milk;
    final tint = milk ? const Color(0xFFFFF6DF) : const Color(0xFFA7E8FA);
    final rimTint = milk ? const Color(0xFFFFFFFF) : const Color(0xFFE0F7FA);

    final sheen = tint.withValues(alpha: fade * (milk ? .16 : .11));
    if (lightRendering) paint.colorFilter = ColorFilter.mode(sheen, BlendMode.srcATop);
    canvas.drawImageRect(image, src, rect, paint);

    // Keep the overhead galantika pot safely inside view regardless of tall/short murti.
    final vesselW = math.max(size.shortestSide * 0.17, rect.width * 0.18).clamp(24.0, 56.0);
    final vesselH = (size.height * 0.052).clamp(11.0, 22.0);
    final spoutY = math.max(vesselH * 1.45, contact.dy - math.max(14.0, size.height * 0.075));
    final spout = Offset(contact.dx, spoutY);
    final vessel = Rect.fromCenter(center: spout - Offset(0, vesselH * 0.55), width: vesselW, height: vesselH);

    final pot = Path()
      ..moveTo(vessel.left, vessel.top)
      ..lineTo(vessel.right, vessel.top)
      ..quadraticBezierTo(vessel.right - vessel.width * .04, vessel.bottom, spout.dx + vessel.width * .09, spout.dy)
      ..lineTo(spout.dx - vessel.width * .09, spout.dy)
      ..quadraticBezierTo(vessel.left + vessel.width * .04, vessel.bottom, vessel.left, vessel.top)
      ..close();
    canvas.drawPath(
      pot,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF79511C),
            const Color(0xFFFFDF89),
            const Color(0xFF966923),
          ].map((c) => c.withValues(alpha: fade)).toList(),
        ).createShader(vessel),
    );
    final rim = Rect.fromCenter(center: vessel.topCenter, width: vessel.width, height: vessel.height * .28);
    canvas.drawOval(rim, Paint()..color = const Color(0xFFDBAC54).withValues(alpha: fade));
    canvas.drawOval(rim.deflate(vessel.width * .04), Paint()..color = const Color(0xFF684322).withValues(alpha: fade));

    // Main pouring stream from vessel spout onto the measured deity crown.
    final streamEndY = math.max(spout.dy + 4, contact.dy + reach * 0.04);
    final pourTip = Offset.lerp(spout, Offset(contact.dx, streamEndY), math.min(1.0, t * 18))!;
    canvas.drawLine(
      spout,
      pourTip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, rect.width * (milk ? .022 : .016))
        ..color = tint.withValues(alpha: fade * (milk ? .90 : .74)),
    );

    // Repeated highlights travel down the continuous pour. Milk moves
    // slightly more slowly than water over the same ritual duration.
    final flowCycles = t * (milk ? 6.0 : 8.0);
    final bead = Offset.lerp(spout, pourTip, flowCycles % 1)!;
    canvas.drawCircle(
      bead,
      math.max(1.1, rect.width * (milk ? .009 : .007)),
      Paint()..color = rimTint.withValues(alpha: fade * .78),
    );

    final depth = reach * ((t - .04) * 4.0).clamp(0.0, 1.0);
    if (depth <= 0) return;

    if (!lightRendering) {
      canvas.saveLayer(rect, Paint());
      canvas.drawRect(rect, Paint()..color = sheen);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, rect.width * (milk ? .015 : .011));

    if (lightRendering) {
      // Sample the portrait alpha directly on each stroke to avoid a separate
      // full-portrait render target and compositing pass on older GPUs.
      stroke.shader = _maskAt(rect);
      stroke.colorFilter = ColorFilter.mode(tint.withValues(alpha: fade * (milk ? .64 : .44)), BlendMode.srcIn);
    }
    final weights = lightRendering ? const [-.7, 0.0, .7] : const [-0.90, -0.45, 0.0, 0.45, 0.90];
    for (var idx = 0; idx < weights.length; idx++) {
      final k = weights[idx];
      final streamScale = 1.0 - 0.18 * k.abs();
      final length = depth * streamScale;
      final path = Path()..moveTo(contact.dx, contact.dy);
      for (var j = 1; j <= 18; j++) {
        final yOff = length * j / 18;
        final u = (yOff / reach).clamp(0.0, 1.0);
        final (leftX, rightX) = profile.boundsAt(u);
        final halfWidth = math.max(rect.width * 0.06, (rightX - leftX) * rect.width * 0.36);
        final bandCenter = rect.left + ((leftX + rightX) * 0.5) * rect.width;
        final targetX = ui.lerpDouble(contact.dx, bandCenter, math.min(1.0, u * 2.2))!;
        final ripple = rect.width * 0.012 * math.sin(u * 9 - flowCycles * math.pi + idx);
        final x = targetX + k * halfWidth * math.min(1.0, u * 3.0 + 0.12) + ripple;
        path.lineTo(x, contact.dy + yOff);
      }
      if (!lightRendering) {
        stroke.shader = ui.Gradient.linear(
          contact,
          contact.translate(0, length),
          [
            rimTint.withValues(alpha: fade * (milk ? .78 : .62)),
            tint.withValues(alpha: fade * (milk ? .48 : .32)),
            tint.withValues(alpha: 0),
          ],
          const [0, .55, 1],
        );
      }
      canvas.drawPath(path, stroke);
    }
    if (!lightRendering) {
      canvas.drawImageRect(image, src, rect, paint..blendMode = BlendMode.dstIn);
      canvas.restore();
    }

    // Pooling glow/droplet shimmer around the measured base width of the murti.
    if (t > 0.28) {
      final poolAlpha = fade * ((t - 0.28) * 1.4).clamp(0.0, 1.0);
      final (baseLeft, baseRight) = profile.boundsAt(1.0);
      final baseSpan = math.max(rect.width * 0.28, (baseRight - baseLeft) * rect.width * 0.78);
      final poolCenter = Offset(rect.left + ((baseLeft + baseRight) * 0.5) * rect.width, baseY - 2);
      canvas.drawOval(
        Rect.fromCenter(center: poolCenter, width: baseSpan, height: math.max(8, rect.height * 0.055)),
        Paint()
          ..shader = ui.Gradient.radial(
            poolCenter,
            baseSpan * 0.52,
            [
              rimTint.withValues(alpha: poolAlpha * (milk ? .42 : .32)),
              tint.withValues(alpha: poolAlpha * .14),
              tint.withValues(alpha: 0),
            ],
            const [0, .58, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_MurtiPainter old) =>
      old.image != image ||
      old.profile != profile ||
      old.progress != progress ||
      old.liquid != liquid ||
      old.lightRendering != lightRendering;
}
