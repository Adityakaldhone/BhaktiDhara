import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Optional photo-real layers. Each has a painted fallback, so a missing or
/// renamed file never breaks the sanctum.
abstract final class MandirAssets {
  static const sanctum = 'assets/mandir/garbhagriha_sanctum.webp';
  static const prabhavaliArch = 'assets/mandir/golden_prabhavali_arch.webp';
  static const akhandDiya = 'assets/mandir/brass_akhand_diya.webp';
  static const gheeKalash = 'assets/mandir/brass_ghee_kalash.webp';
  static const templeBell = 'assets/mandir/brass_temple_bell.webp';
}

/// [asset] when bundled, otherwise [fallback] painted at the same size.
class MandirAssetImage extends StatelessWidget {
  const MandirAssetImage(
    this.asset, {
    super.key,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.cacheWidth,
  });

  final String asset;
  final CustomPainter fallback;
  final BoxFit fit;
  final Alignment alignment;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => CustomPaint(painter: fallback, size: Size.infinite),
    );
  }
}

/// Stable pseudo-random 0..1 for particle [i].
double mandirHash(int i, [int salt = 0]) {
  final x = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
  return x - x.floorToDouble();
}

abstract final class Brass {
  static const highlight = Color(0xFFFFF1C1);
  static const light = Color(0xFFFFE7A0);
  static const gold = Color(0xFFE2B33C);
  static const mid = Color(0xFFC9962E);
  static const dark = Color(0xFF7A5414);
  static const deep = Color(0xFF4A2F0A);

  static Shader body(Rect r, {bool vertical = false}) => LinearGradient(
    begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
    end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    colors: const [dark, light, gold, mid, deep],
    stops: const [0, 0.28, 0.5, 0.78, 1],
  ).createShader(r);

  static Shader dome(Offset c, double r) => RadialGradient(
    center: const Alignment(-0.35, -0.45),
    colors: const [highlight, gold, dark],
    stops: const [0, 0.5, 1],
  ).createShader(Rect.fromCircle(center: c, radius: r));
}

// ═══════════════════════════════════════════════════════════════════════════
//  BACKGROUND PLANE
// ═══════════════════════════════════════════════════════════════════════════

/// Deep maroon sanctum wall over a lamp-lit stone floor.
class SanctumWallPainter extends CustomPainter {
  const SanctumWallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.1,
          colors: [Color(0xFF7A2A16), Color(0xFF4A140B), Color(0xFF1C0704)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    final blocks = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final rowH = size.height / 22;
    for (var r = 0; r < 17; r++) {
      final y = r * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), blocks);
      final off = r.isEven ? 0.0 : size.width / 10;
      for (var x = off; x < size.width; x += size.width / 5) {
        canvas.drawLine(Offset(x, y), Offset(x, y + rowH), blocks);
      }
    }
    final floor = Rect.fromLTWH(0, size.height * 0.76, size.width, size.height * 0.24);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A3418), Color(0xFF2A160A)],
        ).createShader(floor),
    );
    final jali = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.05),
      width: size.width * 0.36,
      height: size.height * 0.04,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(jali, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFFFD27A).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(SanctumWallPainter oldDelegate) => false;
}

/// Slowly turning shafts of Surya light falling from the sanctum skylight.
class GodRaysPainter extends CustomPainter {
  GodRaysPainter(this.clock) : super(repaint: clock);

  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final origin = Offset(size.width * 0.5, -size.height * 0.04);
    final length = size.height * 0.95;
    const rays = 9;
    final drift = math.sin(t * 0.15) * 0.12;
    for (var i = 0; i < rays; i++) {
      final base = math.pi / 2 + (i - (rays - 1) / 2) * 0.13 + drift;
      final width = 0.035 + mandirHash(i, 3) * 0.04;
      final pulse = 0.55 + 0.45 * math.sin(t * (0.4 + mandirHash(i, 5) * 0.5) + i);
      final a = base - width;
      final b = base + width;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(origin.dx + math.cos(a) * length, origin.dy + math.sin(a) * length)
        ..lineTo(origin.dx + math.cos(b) * length, origin.dy + math.sin(b) * length)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(
            origin,
            length,
            [
              const Color(0xFFFFD27A).withValues(alpha: 0.20 * pulse),
              const Color(0xFFFFB347).withValues(alpha: 0.07 * pulse),
              const Color(0x00FFB347),
            ],
            const [0, 0.55, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(GodRaysPainter oldDelegate) => oldDelegate.clock != clock;
}

/// Golden prana motes rising through the light.
class PranaDustPainter extends CustomPainter {
  PranaDustPainter(this.clock, {this.count = 56}) : super(repaint: clock);

  final ValueListenable<double> clock;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final glow = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < count; i++) {
      final speed = 0.025 + mandirHash(i, 1) * 0.05;
      final phase = mandirHash(i, 2);
      final life = (t * speed + phase) % 1.0;
      final x = mandirHash(i) * size.width + math.sin(t * 0.7 + phase * 9) * 14;
      final y = size.height * (1.05 - life * 1.1);
      final r = 0.8 + mandirHash(i, 4) * 1.8;
      final twinkle = 0.5 + 0.5 * math.sin(t * 3 + i);
      final fade = math.sin(life * math.pi);
      final a = (0.65 * twinkle * fade).clamp(0.0, 1.0);
      glow.color = const Color(0xFFFFD27A).withValues(alpha: a * 0.25);
      canvas.drawCircle(Offset(x, y), r * 3.2, glow);
      glow.color = const Color(0xFFFFF3C4).withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, glow);
    }
  }

  @override
  bool shouldRepaint(PranaDustPainter oldDelegate) => oldDelegate.clock != clock;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ARCH + DEITY PLANES
// ═══════════════════════════════════════════════════════════════════════════

/// Golden Prabhavali: flame-crowned arch on two pillars over a lotus base.
class PrabhavaliArchPainter extends CustomPainter {
  const PrabhavaliArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final band = w * 0.075;
    final arch = Path()
      ..moveTo(w * 0.12, h * 0.82)
      ..lineTo(w * 0.12, h * 0.42)
      ..cubicTo(w * 0.12, h * 0.05, w * 0.88, h * 0.05, w * 0.88, h * 0.42)
      ..lineTo(w * 0.88, h * 0.82);
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band
        ..shader = Brass.body(rect),
    );
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band * 0.18
        ..color = Brass.highlight.withValues(alpha: 0.6),
    );

    final metrics = arch.computeMetrics().first;
    final flame = Paint()..shader = Brass.body(rect, vertical: true);
    for (var d = 0.0; d < metrics.length; d += band * 0.9) {
      final tan = metrics.getTangentForOffset(d);
      if (tan == null) continue;
      final n = Offset(-tan.vector.dy, tan.vector.dx);
      final outward = (tan.position - Offset(w / 2, h * 0.45)).direction;
      final dir = (n.direction - outward).abs() < math.pi / 2 ? n : -n;
      final base = tan.position + dir * band * 0.5;
      final tip = base + dir * band * 0.9;
      final side = Offset(-dir.dy, dir.dx) * band * 0.32;
      canvas.drawPath(
        Path()
          ..moveTo((base + side).dx, (base + side).dy)
          ..quadraticBezierTo((tip + side * 0.6).dx, (tip + side * 0.6).dy, tip.dx, tip.dy)
          ..quadraticBezierTo((tip - side * 0.6).dx, (tip - side * 0.6).dy, (base - side).dx, (base - side).dy)
          ..close(),
        flame,
      );
    }

    final crown = Offset(w / 2, h * 0.13);
    canvas.drawCircle(crown, w * 0.07, Paint()..shader = Brass.dome(crown, w * 0.07));
    canvas.drawCircle(crown, w * 0.022, Paint()..color = const Color(0xFFB71C1C));

    final base = Rect.fromLTWH(w * 0.03, h * 0.82, w * 0.94, h * 0.16);
    for (var i = 0; i < 11; i++) {
      final cx = base.left + base.width * (i + 0.5) / 11;
      final petal = Path()
        ..moveTo(cx - base.width / 22, base.bottom)
        ..quadraticBezierTo(cx - base.width / 30, base.top + base.height * 0.15, cx, base.top)
        ..quadraticBezierTo(cx + base.width / 30, base.top + base.height * 0.15, cx + base.width / 22, base.bottom)
        ..close();
      canvas.drawPath(petal, Paint()..shader = Brass.body(base, vertical: true));
      canvas.drawPath(
        petal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Brass.deep.withValues(alpha: 0.5),
      );
    }
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.80, w * 0.84, h * 0.05), Paint()..shader = Brass.body(base));
  }

  @override
  bool shouldRepaint(PrabhavaliArchPainter oldDelegate) => false;
}

/// Golden Sinhasan with a red velvet gaddi and lion-paw scrolls.
class SinhasanPainter extends CustomPainter {
  const SinhasanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawOval(
      Rect.fromLTWH(w * 0.02, h * 0.78, w * 0.96, h * 0.24),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final plinth = Path()
      ..moveTo(w * 0.04, h * 0.92)
      ..lineTo(w * 0.96, h * 0.92)
      ..lineTo(w * 0.88, h * 0.42)
      ..lineTo(w * 0.12, h * 0.42)
      ..close();
    canvas.drawPath(plinth, Paint()..shader = Brass.body(rect));
    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Brass.deep.withValues(alpha: 0.6);
    for (final f in const [0.56, 0.7, 0.84]) {
      canvas.drawLine(Offset(w * (0.1 - (f - 0.42) * 0.1), h * f), Offset(w * (0.9 + (f - 0.42) * 0.1), h * f), trim);
    }
    for (var i = 0; i < 7; i++) {
      final c = Offset(w * (0.2 + i * 0.1), h * 0.63);
      canvas.drawCircle(c, w * 0.014, Paint()..color = i.isEven ? const Color(0xFFC62828) : const Color(0xFF1B7A4A));
    }
    final gaddi = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.18, w * 0.72, h * 0.3),
      Radius.circular(h * 0.15),
    );
    canvas.drawRRect(
      gaddi,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE53935), Color(0xFF8E0E0E)],
        ).createShader(gaddi.outerRect),
    );
    canvas.drawRRect(
      gaddi,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Brass.gold,
    );
    for (final left in const [true, false]) {
      final x = left ? w * 0.06 : w * 0.94;
      final c = Offset(x, h * 0.5);
      canvas.drawCircle(c, h * 0.2, Paint()..shader = Brass.dome(c, h * 0.2));
      canvas.drawArc(Rect.fromCircle(center: c, radius: h * 0.12), left ? 0 : math.pi, math.pi * 1.4, false, trim);
    }
  }

  @override
  bool shouldRepaint(SinhasanPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  FLAME, DIYA, KALASH, GHEE
// ═══════════════════════════════════════════════════════════════════════════

/// Multi-layer living flame rooted at the bottom-centre of its box.
/// [intensity] 0 shows a smoking wick; [surge] briefly flares it.
class FlamePainter extends CustomPainter {
  FlamePainter({required this.clock, required this.intensity, this.surge, this.seed = 0, this.lean = 0})
    : super(repaint: Listenable.merge([clock, ?surge]));

  final ValueListenable<double> clock;
  final double intensity;
  final Animation<double>? surge;
  final int seed;

  /// -1..1: pushes the flame tip sideways, as when the lamp is moved.
  final double lean;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value + seed * 1.7;
    final boost = 1 + 0.65 * (surge?.value ?? 0);
    final k = intensity * boost;
    final base = Offset(size.width / 2, size.height * 0.96);

    if (intensity <= 0.01) {
      for (var i = 0; i < 6; i++) {
        final life = (t * 0.35 + i / 6) % 1.0;
        final p = base + Offset(math.sin(t * 2 + i) * 6 * life, -size.height * 0.8 * life);
        canvas.drawCircle(
          p,
          2 + life * 7,
          Paint()
            ..color = const Color(0xFFBDB6AA).withValues(alpha: 0.35 * (1 - life))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      return;
    }

    final flicker = 1 + 0.06 * math.sin(t * 11) + 0.04 * math.sin(t * 23 + 1.3);
    final h = size.height * 0.78 * k.clamp(0.0, 1.6) * flicker;
    final w = size.width * 0.32 * (0.6 + 0.4 * k.clamp(0.0, 1.6));
    final sway = math.sin(t * 6.5) * w * 0.22 + math.sin(t * 13.1) * w * 0.08 + lean.clamp(-1.0, 1.0) * w * 1.4;

    final halo = base.translate(0, -h * 0.4);
    canvas.drawCircle(
      halo,
      h * 0.95,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(halo, h * 0.95, [
          const Color(0xFFFFA726).withValues(alpha: 0.42 * k.clamp(0.0, 1.0)),
          const Color(0x00FF6F00),
        ]),
    );

    Path tongue(double scale) {
      final hh = h * scale;
      final ww = w * scale;
      final tip = base + Offset(sway * scale, -hh);
      return Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(base.dx - ww, base.dy - hh * 0.15, tip.dx - ww * 0.55, tip.dy + hh * 0.45, tip.dx, tip.dy)
        ..cubicTo(tip.dx + ww * 0.55, tip.dy + hh * 0.45, base.dx + ww, base.dy - hh * 0.15, base.dx, base.dy)
        ..close();
    }

    final outer = tongue(1);
    canvas.drawPath(
      outer,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..shader = ui.Gradient.linear(
          base,
          base.translate(0, -h),
          const [Color(0xFFFF6F00), Color(0xFFFF9800), Color(0x00FF5722)],
          const [0, 0.55, 1],
        ),
    );
    canvas.drawPath(
      tongue(0.7),
      Paint()
        ..shader = ui.Gradient.linear(
          base,
          base.translate(0, -h * 0.7),
          const [Color(0xFFFFD54F), Color(0xFFFFEB3B), Color(0x00FFF59D)],
          const [0, 0.6, 1],
        ),
    );
    canvas.drawPath(
      tongue(0.38),
      Paint()
        ..shader = ui.Gradient.linear(
          base,
          base.translate(0, -h * 0.38),
          const [Color(0xFF90CAF9), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          const [0, 0.35, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(FlamePainter oldDelegate) =>
      oldDelegate.intensity != intensity ||
      oldDelegate.clock != clock ||
      oldDelegate.surge != surge ||
      oldDelegate.lean != lean;
}

/// Engraved brass akhand diya on a stand; [ghee] 0..1 fills the bowl.
class BrassDiyaPainter extends CustomPainter {
  const BrassDiyaPainter({this.ghee = 1});

  final double ghee;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final foot = Rect.fromLTWH(w * 0.32, h * 0.8, w * 0.36, h * 0.12);
    canvas.drawOval(foot, Paint()..shader = Brass.body(foot));
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.58, w * 0.12, h * 0.26), Paint()..shader = Brass.body(rect));
    final bowl = Path()
      ..moveTo(w * 0.24, h * 0.25)
      ..quadraticBezierTo(w * 0.26, h * 0.62, w * 0.5, h * 0.62)
      ..quadraticBezierTo(w * 0.74, h * 0.62, w * 0.76, h * 0.25)
      ..close();
    canvas.drawPath(bowl, Paint()..shader = Brass.body(rect));
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Brass.deep.withValues(alpha: 0.55);
    for (var i = 0; i < 9; i++) {
      final x = w * (0.3 + i * 0.05);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, h * 0.42), width: w * 0.035, height: h * 0.09), band);
    }
    final rim = Rect.fromLTWH(w * 0.22, h * 0.19, w * 0.56, h * 0.12);
    canvas.drawOval(rim, Paint()..shader = Brass.body(rim));
    canvas.drawOval(
      rim.deflate(w * 0.025),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(const Color(0xFF5A3A10), const Color(0xFFF2B630), ghee)!,
            Color.lerp(const Color(0xFF3A240A), const Color(0xFFFFD55A), ghee)!,
          ],
        ).createShader(rim),
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.49, h * 0.12, w * 0.02, h * 0.13), Paint()..color = const Color(0xFFF5EBDD));
  }

  @override
  bool shouldRepaint(BrassDiyaPainter oldDelegate) => oldDelegate.ghee != ghee;
}

/// Brass lota-kalash with a long spout pointing left.
class KalashPainter extends CustomPainter {
  const KalashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final spout = Path()
      ..moveTo(w * 0.36, h * 0.52)
      ..quadraticBezierTo(w * 0.18, h * 0.42, w * 0.04, h * 0.18)
      ..lineTo(w * 0.1, h * 0.16)
      ..quadraticBezierTo(w * 0.24, h * 0.34, w * 0.38, h * 0.38)
      ..close();
    canvas.drawPath(spout, Paint()..shader = Brass.body(rect, vertical: true));
    final bodyC = Offset(w * 0.6, h * 0.58);
    canvas.drawOval(
      Rect.fromCenter(center: bodyC, width: w * 0.62, height: h * 0.62),
      Paint()..shader = Brass.body(rect),
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.16, w * 0.28, h * 0.16), Paint()..shader = Brass.body(rect));
    final mouth = Rect.fromLTWH(w * 0.38, h * 0.08, w * 0.44, h * 0.1);
    canvas.drawOval(mouth, Paint()..shader = Brass.body(mouth));
    canvas.drawOval(mouth.deflate(w * 0.03), Paint()..color = const Color(0xFFF2B630));
    final foot = Rect.fromLTWH(w * 0.44, h * 0.86, w * 0.32, h * 0.1);
    canvas.drawRect(foot, Paint()..shader = Brass.body(foot));
    final lotus = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Brass.deep.withValues(alpha: 0.6);
    canvas.drawArc(Rect.fromCenter(center: bodyC, width: w * 0.2, height: h * 0.2), math.pi, math.pi, false, lotus);
    canvas.drawLine(bodyC.translate(-w * 0.28, -h * 0.12), bodyC.translate(w * 0.28, -h * 0.12), lotus);
  }

  @override
  bool shouldRepaint(KalashPainter oldDelegate) => false;
}

/// Curved stream of molten ghee from [from] (spout) into [to] (diya bowl)
/// with glowing droplets. [flow] 0..1 fades the stream in and out.
class GheeStreamPainter extends CustomPainter {
  const GheeStreamPainter({required this.from, required this.to, required this.flow, required this.t});

  final Offset from;
  final Offset to;
  final double flow;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (flow <= 0.01) return;
    final ctrl = Offset(from.dx - (from.dx - to.dx) * 0.15, from.dy + (to.dy - from.dy) * 0.15);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
    final shader = ui.Gradient.linear(
      from,
      to,
      [
        const Color(0xFFFFE082).withValues(alpha: flow),
        const Color(0xFFFFB300).withValues(alpha: flow),
        const Color(0xFFFFD54F).withValues(alpha: flow * 0.9),
      ],
      const [0, 0.6, 1],
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9 * flow
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.35 * flow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.4 * flow
        ..shader = shader,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.55 * flow),
    );

    Offset at(double s) {
      final u = 1 - s;
      return from * (u * u) + ctrl * (2 * u * s) + to * (s * s);
    }

    final drop = Paint();
    for (var i = 0; i < 9; i++) {
      final s = (t * 1.6 + i / 9) % 1.0;
      final p = at(s) + Offset(math.sin(t * 9 + i) * 2.5, 0);
      drop.color = const Color(0xFFFFD54F).withValues(alpha: 0.35 * flow);
      canvas.drawCircle(p, 4.5, drop);
      drop.color = const Color(0xFFFFF8E1).withValues(alpha: flow);
      canvas.drawCircle(p, 1.8, drop);
    }
    final splash = Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.7 * flow);
    for (var i = 0; i < 6; i++) {
      final life = (t * 2.2 + i / 6) % 1.0;
      final dir = (i.isEven ? -1 : 1) * (0.4 + mandirHash(i, 9) * 0.8);
      final p = to + Offset(dir * 14 * life, -10 * math.sin(life * math.pi));
      canvas.drawCircle(p, 1.6 * (1 - life), splash);
    }
  }

  @override
  bool shouldRepaint(GheeStreamPainter oldDelegate) =>
      oldDelegate.flow != flow || oldDelegate.t != t || oldDelegate.from != from || oldDelegate.to != to;
}

/// Brass dhoop stand with three agarbattis and drifting volumetric smoke.
class DhoopSmokePainter extends CustomPainter {
  DhoopSmokePainter(this.clock) : super(repaint: clock);

  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final w = size.width;
    final h = size.height;
    final holder = Rect.fromLTWH(w * 0.3, h * 0.88, w * 0.4, h * 0.1);
    canvas.drawOval(holder, Paint()..shader = Brass.body(holder));
    final sticks = [
      (Offset(w * 0.42, h * 0.9), -0.18),
      (Offset(w * 0.5, h * 0.9), 0.0),
      (Offset(w * 0.58, h * 0.9), 0.18),
    ];
    final stick = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5D2E16);
    final smoke = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    for (var s = 0; s < sticks.length; s++) {
      final (root, lean) = sticks[s];
      final tip = root + Offset(math.sin(lean) * h * 0.32, -h * 0.32);
      canvas.drawLine(root, tip, stick);
      canvas.drawCircle(
        tip,
        2.4,
        Paint()
          ..color = const Color(0xFFFF7043)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + math.sin(t * 4 + s)),
      );
      for (var i = 0; i < 12; i++) {
        final life = (t * 0.18 + i / 12 + s * 0.31) % 1.0;
        final rise = life * h * 0.62;
        final curl = math.sin(life * 7 + t * 0.9 + s * 2) * (6 + life * 22);
        final p = tip + Offset(curl, -rise);
        smoke.color = const Color(0xFFEDE7DB).withValues(alpha: 0.32 * math.sin(life * math.pi));
        canvas.drawCircle(p, 4 + life * 16, smoke);
      }
    }
  }

  @override
  bool shouldRepaint(DhoopSmokePainter oldDelegate) => oldDelegate.clock != clock;
}

/// Rosewood chowki draped in a red, gold-bordered altar cloth.
class AltarPainter extends CustomPainter {
  const AltarPainter({this.topFraction = 0.26});

  /// Share of the height taken by the chowki's top surface.
  final double topFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final topH = h * topFraction;

    final top = Path()
      ..moveTo(w * 0.08, 0)
      ..lineTo(w * 0.92, 0)
      ..lineTo(w, topH)
      ..lineTo(0, topH)
      ..close();
    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3E1D0C), Color(0xFF6E3A1A), Color(0xFF5A2D14)],
          stops: [0, 0.7, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, topH)),
    );
    // Lamp glow pooling on the polished rosewood.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.44, topH * 0.55), width: w * 0.6, height: topH * 0.8),
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(Offset(w * 0.44, topH * 0.55), w * 0.3, [
          const Color(0x33FFB74D),
          const Color(0x00FFB74D),
        ]),
    );

    final front = Rect.fromLTWH(0, topH, w, h - topH);
    canvas.drawRect(
      front,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2410), Color(0xFF1E0C05)],
        ).createShader(front),
    );
    final carve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFD9A54A).withValues(alpha: 0.35);
    for (var i = 0; i < 4; i++) {
      final panel = Rect.fromLTWH(w * (0.03 + i * 0.245), topH + h * 0.08, w * 0.205, h * 0.32);
      canvas.drawRRect(RRect.fromRectAndRadius(panel, const Radius.circular(6)), carve);
      final c = panel.center;
      for (var p = 0; p < 8; p++) {
        final a = p * math.pi / 4;
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(math.cos(a), math.sin(a)) * panel.shortestSide * 0.18,
            width: panel.shortestSide * 0.16,
            height: panel.shortestSide * 0.16,
          ),
          carve,
        );
      }
    }

    final rail = Rect.fromLTWH(0, topH - 3, w, 6);
    canvas.drawRect(rail, Paint()..shader = Brass.body(rail, vertical: true));

    // Red runner across the chowki, hanging over the front edge.
    final hem = topH + h * 0.16;
    final runner = Path()
      ..moveTo(w * 0.3, h * 0.01)
      ..lineTo(w * 0.7, h * 0.01)
      ..lineTo(w * 0.76, topH)
      ..lineTo(w * 0.76, hem);
    const scallops = 9;
    for (var i = scallops; i > 0; i--) {
      final x0 = w * (0.24 + 0.52 * i / scallops);
      final x1 = w * (0.24 + 0.52 * (i - 1) / scallops);
      runner.quadraticBezierTo((x0 + x1) / 2, hem + h * 0.06, x1, hem);
    }
    runner
      ..lineTo(w * 0.24, topH)
      ..close();
    canvas.drawPath(
      runner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFF8E0E0E)],
          stops: [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, hem + h * 0.06)),
    );
    canvas.drawPath(
      runner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Brass.gold,
    );
    final zari = Paint()..color = Brass.light.withValues(alpha: 0.9);
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(Offset(w * (0.27 + i * 0.46 / 11), topH + h * 0.06), 1.8, zari);
    }
    for (var i = 0; i <= scallops; i++) {
      final x = w * (0.24 + 0.52 * i / scallops);
      final tassel = Offset(x, hem + h * 0.035);
      canvas.drawLine(
        Offset(x, hem),
        tassel,
        Paint()
          ..strokeWidth = 1
          ..color = Brass.gold,
      );
      canvas.drawCircle(tassel, 2.6, Paint()..shader = Brass.dome(tassel, 2.6));
    }
  }

  @override
  bool shouldRepaint(AltarPainter oldDelegate) => oldDelegate.topFraction != topFraction;
}

/// Brass bhog thali with modaks and ladoos.
class NaivedyaPainter extends CustomPainter {
  const NaivedyaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final plate = Rect.fromLTWH(0, h * 0.55, w, h * 0.42);
    canvas.drawOval(plate.shift(const Offset(0, 4)), Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawOval(plate, Paint()..shader = Brass.body(plate));
    canvas.drawOval(plate.deflate(w * 0.06), Paint()..shader = Brass.body(plate, vertical: true));
    for (var i = 0; i < 3; i++) {
      final c = Offset(w * (0.28 + i * 0.22), h * 0.62);
      final r = w * 0.1;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: const [Color(0xFFFFCC80), Color(0xFFF57C00), Color(0xFFB34700)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      for (var d = 0; d < 6; d++) {
        final a = d * 1.1 + i;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
          0.9,
          Paint()..color = const Color(0xFFFFE0B2),
        );
      }
    }
    for (var i = 0; i < 2; i++) {
      final cx = w * (0.39 + i * 0.22);
      final base = h * 0.58;
      final mh = h * 0.42;
      final mw = w * 0.11;
      final modak = Path()
        ..moveTo(cx, base - mh)
        ..cubicTo(cx + mw * 0.3, base - mh * 0.6, cx + mw, base - mh * 0.3, cx + mw * 0.8, base)
        ..lineTo(cx - mw * 0.8, base)
        ..cubicTo(cx - mw, base - mh * 0.3, cx - mw * 0.3, base - mh * 0.6, cx, base - mh)
        ..close();
      canvas.drawPath(
        modak,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFDF5), Color(0xFFF1DFC0)],
          ).createShader(Rect.fromLTWH(cx - mw, base - mh, mw * 2, mh)),
      );
      final ridge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFC9A877);
      for (var r = -2; r <= 2; r++) {
        canvas.drawLine(Offset(cx, base - mh * 0.95), Offset(cx + r * mw * 0.32, base), ridge);
      }
    }
  }

  @override
  bool shouldRepaint(NaivedyaPainter oldDelegate) => false;
}

/// Hand-beaten brass pooja thali seen from a slight height: thick rim,
/// beaded edge, embossed lotus well, kumkum and haldi katoris, akshata,
/// marigolds, a rose and a betel leaf. The lit diya sits on top as a widget.
class AartiThaliPainter extends CustomPainter {
  const AartiThaliPainter();

  /// Plate ellipse height / width.
  static const squash = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rx = size.width / 2;
    final ry = rx * squash;
    final thick = ry * 0.16;
    final c = Offset(rx, size.height - ry - thick);

    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, thick * 2.2), width: rx * 2.05, height: ry * 2.1),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final top = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    final side = top.shift(Offset(0, thick));
    canvas.drawOval(
      side,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5A3A0C), Color(0xFFB8862A), Color(0xFF6B4510), Color(0xFF3A2406)],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(side),
    );

    canvas.drawOval(
      top,
      Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          colors: const [
            Color(0xFFFFE9A8),
            Color(0xFFB98328),
            Color(0xFFF7D27A),
            Color(0xFF8E6118),
            Color(0xFFFFE9A8),
            Color(0xFFA8761F),
            Color(0xFFF2C766),
            Color(0xFF7A5414),
            Color(0xFFFFE9A8),
          ],
        ).createShader(top),
    );

    final bead = rx * 0.032;
    for (var i = 0; i < 40; i++) {
      final a = i * math.pi * 2 / 40;
      final p = c + Offset(math.cos(a) * rx * 0.94, math.sin(a) * ry * 0.92);
      canvas.drawCircle(p, bead, Paint()..shader = Brass.dome(p, bead));
    }

    final well = Rect.fromCenter(center: c, width: rx * 1.62, height: ry * 1.56);
    canvas.drawOval(
      well,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.9,
          colors: const [Color(0xFFFFF0B8), Color(0xFFE2B33C), Color(0xFFA8761F), Color(0xFF6B4510)],
          stops: const [0, 0.35, 0.78, 1],
        ).createShader(well),
    );
    // Recessed lip: shadow on the far edge, light on the near edge.
    canvas.drawArc(
      well,
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ry * 0.07
        ..color = const Color(0xFF4A2F0A).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawArc(
      well,
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ry * 0.04
        ..color = Brass.highlight.withValues(alpha: 0.7),
    );

    final engrave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Brass.deep.withValues(alpha: 0.45);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi * 2 / 16;
      final dir = Offset(math.cos(a), math.sin(a) * squash);
      final base = c + Offset(dir.dx * rx * 0.5, dir.dy * rx * 0.5);
      final tip = c + Offset(dir.dx * rx * 0.74, dir.dy * rx * 0.74);
      final n = Offset(-dir.dy, dir.dx) * rx * 0.07;
      final mid = Offset.lerp(base, tip, 0.5)!;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo((mid + n).dx, (mid + n).dy, tip.dx, tip.dy)
          ..quadraticBezierTo((mid - n).dx, (mid - n).dy, base.dx, base.dy),
        engrave,
      );
    }

    canvas.drawArc(
      top.deflate(rx * 0.02),
      math.pi * 1.1,
      math.pi * 0.45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ry * 0.06
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    _leaf(canvas, c + Offset(-rx * 0.42, ry * 0.18), rx * 0.3, -0.5);
    _katori(canvas, c + Offset(-rx * 0.5, -ry * 0.28), rx * 0.16, const Color(0xFFD50000), const Color(0xFF7F0000));
    _katori(canvas, c + Offset(rx * 0.5, -ry * 0.3), rx * 0.15, const Color(0xFFFFC400), const Color(0xFFE65100));
    final rice = c + Offset(rx * 0.46, ry * 0.3);
    for (var i = 0; i < 28; i++) {
      final a = mandirHash(i, 61) * math.pi * 2;
      final d = math.sqrt(mandirHash(i, 62));
      final p = rice + Offset(math.cos(a) * d * rx * 0.16, math.sin(a) * d * ry * 0.22 - (1 - d) * ry * 0.08);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a * 1.7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 0.05, height: rx * 0.022),
        Paint()..color = Color.lerp(const Color(0xFFFFFDF2), const Color(0xFFE8DCC0), mandirHash(i, 63))!,
      );
      canvas.restore();
    }
    _marigold(canvas, c + Offset(-rx * 0.25, ry * 0.45), rx * 0.15);
    _marigold(canvas, c + Offset(rx * 0.12, ry * 0.55), rx * 0.12);
    _rose(canvas, c + Offset(-rx * 0.62, ry * 0.32), rx * 0.1);
  }

  static void _katori(Canvas canvas, Offset c, double r, Color powder, Color powderDark) {
    final body = Rect.fromCenter(center: c.translate(0, r * 0.35), width: r * 1.8, height: r * 1.1);
    canvas.drawOval(body.shift(Offset(0, r * 0.25)), Paint()..color = Colors.black.withValues(alpha: 0.3));
    canvas.drawArc(body, 0, math.pi, true, Paint()..shader = Brass.body(body));
    final rim = Rect.fromCenter(center: c.translate(0, r * 0.35), width: r * 1.8, height: r * 0.7);
    canvas.drawOval(rim, Paint()..shader = Brass.body(rim, vertical: true));
    final mound = Rect.fromCenter(center: c.translate(0, r * 0.25), width: r * 1.5, height: r * 0.75);
    canvas.drawOval(
      mound,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          colors: [Color.lerp(powder, Colors.white, 0.25)!, powder, powderDark],
          stops: const [0, 0.5, 1],
        ).createShader(mound),
    );
  }

  static void _marigold(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c.translate(0, r * 0.2), r, Paint()..color = Colors.black.withValues(alpha: 0.25));
    const rings = [(16, 1.0), (12, 0.72), (8, 0.45)];
    for (final (n, scale) in rings) {
      for (var i = 0; i < n; i++) {
        final a = i * math.pi * 2 / n + scale;
        final p = c + Offset(math.cos(a), math.sin(a) * 0.8) * r * scale * 0.62;
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(a);
        final petal = Rect.fromCenter(center: Offset.zero, width: r * 0.55 * scale + r * 0.15, height: r * 0.34);
        canvas.drawOval(
          petal,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Color.lerp(const Color(0xFFE65100), const Color(0xFFFF8F00), scale)!,
                Color.lerp(const Color(0xFFFFB300), const Color(0xFFFFD54F), scale)!,
              ],
            ).createShader(petal),
        );
        canvas.restore();
      }
    }
    canvas.drawCircle(c, r * 0.16, Paint()..color = const Color(0xFFBF5600));
  }

  static void _rose(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF7F0019), Color(0xFFD81B60), Color(0xFF8E0E2E)],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final swirl = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..color = const Color(0xFF5A0012).withValues(alpha: 0.6);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r * (0.3 + i * 0.22)), i * 1.9, math.pi * 1.2, false, swirl);
    }
  }

  static void _leaf(Canvas canvas, Offset c, double len, double angle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(-len / 2, 0)
      ..cubicTo(-len * 0.2, -len * 0.42, len * 0.3, -len * 0.3, len / 2, 0)
      ..cubicTo(len * 0.3, len * 0.3, -len * 0.2, len * 0.42, -len / 2, 0)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
        ).createShader(Rect.fromCenter(center: Offset.zero, width: len, height: len * 0.6)),
    );
    canvas.drawLine(
      Offset(-len / 2, 0),
      Offset(len / 2, 0),
      Paint()
        ..strokeWidth = 0.8
        ..color = const Color(0xFFC5E1A5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AartiThaliPainter oldDelegate) => false;
}

/// One spark of the aarti light trail, born at [born] clock-seconds.
class AartiSpark {
  AartiSpark(this.position, this.born, this.seed);

  final Offset position;
  final double born;
  final int seed;
}

/// Fading golden sparks left along the thali's circular path.
class SparkTrailPainter extends CustomPainter {
  SparkTrailPainter({required this.clock, required this.sparks}) : super(repaint: clock);

  static const life = 1.2;

  final ValueListenable<double> clock;
  final List<AartiSpark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.value;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (final s in sparks) {
      final age = (now - s.born) / life;
      if (age < 0 || age > 1) continue;
      final fade = 1 - age;
      final drift = Offset((mandirHash(s.seed, 1) - 0.5) * 18 * age, -14 * age);
      final p = s.position + drift;
      paint.color = const Color(0xFFFFB300).withValues(alpha: 0.3 * fade);
      canvas.drawCircle(p, 6 * fade + 1, paint);
      paint.color = const Color(0xFFFFF3C4).withValues(alpha: 0.9 * fade);
      canvas.drawCircle(p, 1.8 * fade + 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(SparkTrailPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
//  PUSHPANJALI, TILAK, BLESSINGS, SHANKH
// ═══════════════════════════════════════════════════════════════════════════

/// 35 marigold and rose petals drifting down on sinusoidal air currents.
class PetalRainPainter extends CustomPainter {
  PetalRainPainter(this.progress, {this.count = 35, this.seconds = 5.5}) : super(repaint: progress);

  final Animation<double> progress;
  final int count;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0 || p >= 1) return;
    final time = p * seconds;
    for (var i = 0; i < count; i++) {
      final delay = mandirHash(i, 31) * 0.4;
      final local = (p - delay) / (1 - delay);
      if (local <= 0 || local >= 1) continue;
      final x0 = (0.08 + mandirHash(i, 32) * 0.84) * size.width;
      final amp = 12 + mandirHash(i, 33) * 26;
      final freq = 1.2 + mandirHash(i, 34) * 1.6;
      final x = x0 + math.sin(time * freq + i) * amp;
      final y = -20 + local * size.height * (0.72 + mandirHash(i, 35) * 0.2);
      final spin = time * (1.5 + mandirHash(i, 36) * 3) * (i.isEven ? 1 : -1);
      final flip = 0.35 + 0.65 * math.cos(time * freq * 1.3 + i).abs();
      final fade = local > 0.85 ? (1 - local) / 0.15 : 1.0;
      final rose = i % 3 == 0;
      final len = rose ? 11.0 : 9.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.scale(1, flip);
      final petal = Path()
        ..moveTo(0, -len / 2)
        ..quadraticBezierTo(len * 0.55, -len * 0.1, 0, len / 2)
        ..quadraticBezierTo(-len * 0.55, -len * 0.1, 0, -len / 2)
        ..close();
      canvas.drawPath(
        petal,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, -len / 2),
            Offset(0, len / 2),
            rose
                ? [const Color(0xFFFF5C7A).withValues(alpha: fade), const Color(0xFFB0102E).withValues(alpha: fade)]
                : [const Color(0xFFFFD54F).withValues(alpha: fade), const Color(0xFFFF8F00).withValues(alpha: fade)],
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PetalRainPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Marigold-and-rose mala that drops onto the murti's shoulders as
/// [progress] runs 0 → 1. Painted in the murti's own box.
class GarlandPainter extends CustomPainter {
  const GarlandPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final a = Offset(size.width * 0.24, size.height * 0.3);
    final b = Offset(size.width * 0.76, size.height * 0.3);
    final low = Offset(size.width * 0.5, size.height * 0.78);
    const beads = 30;
    final r = size.width * 0.034;
    for (var i = 0; i <= beads; i++) {
      final s = i / beads;
      final reveal = ((progress * 1.4) - (s - 0.5).abs() * 0.8).clamp(0.0, 1.0);
      if (reveal <= 0) continue;
      final u = 1 - s;
      final ctrl = Offset(size.width / 2, low.dy * 1.12);
      final p = a * (u * u) + ctrl * (2 * u * s) + b * (s * s);
      final pos = p.translate(0, -(1 - Curves.easeOutBack.transform(reveal)) * 30);
      final rose = i % 5 == 2;
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: rose
                ? const [Color(0xFFFF6B81), Color(0xFFB0102E)]
                : (i.isEven
                      ? const [Color(0xFFFFE082), Color(0xFFFF8F00)]
                      : const [Color(0xFFFFB74D), Color(0xFFE65100)]),
          ).createShader(Rect.fromCircle(center: pos, radius: r)),
      );
      final ruffle = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.black.withValues(alpha: 0.18);
      canvas.drawCircle(pos, r * 0.55, ruffle);
    }
    if (progress > 0.7) {
      final tassel = (progress - 0.7) / 0.3;
      final top = Offset(size.width / 2, low.dy * 0.98);
      for (var i = 0; i < 3; i++) {
        final p = top.translate(0, r * 2 * (i + 1) * tassel);
        canvas.drawCircle(p, r * 0.9, Paint()..color = i == 1 ? const Color(0xFFB0102E) : const Color(0xFFFFA000));
      }
    }
  }

  @override
  bool shouldRepaint(GarlandPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Kumkum and chandan tilak with akshata, centred in its box.
class TilakPainter extends CustomPainter {
  const TilakPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final s = size.shortestSide;
    final grow = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final glow = (1 - progress).clamp(0.0, 1.0);

    canvas.drawCircle(
      c,
      s * 0.5,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(c, s * 0.5, [
          const Color(0xFFFF5252).withValues(alpha: 0.55 * glow + 0.12),
          const Color(0x00FF5252),
        ]),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(grow);
    final chandan = Path()
      ..moveTo(-s * 0.16, -s * 0.34)
      ..quadraticBezierTo(-s * 0.18, s * 0.26, 0, s * 0.3)
      ..quadraticBezierTo(s * 0.18, s * 0.26, s * 0.16, -s * 0.34);
    canvas.drawPath(
      chandan,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.07
        ..color = const Color(0xFFFFE9B0),
    );
    final kumkum = Path()
      ..moveTo(0, -s * 0.3)
      ..quadraticBezierTo(s * 0.06, 0, 0, s * 0.18)
      ..quadraticBezierTo(-s * 0.06, 0, 0, -s * 0.3)
      ..close();
    canvas.drawPath(
      kumkum,
      Paint()
        ..color = const Color(0xFFE0001B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    for (var i = 0; i < 7; i++) {
      final a = mandirHash(i, 41) * math.pi * 2;
      final d = s * (0.12 + mandirHash(i, 42) * 0.1);
      final p = Offset(math.cos(a) * d * 0.7, s * 0.24 + math.sin(a) * d * 0.4);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.06, height: s * 0.028),
        Paint()..color = const Color(0xFFFFFDF2),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TilakPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Golden blessing particles rising from the Sinhasan feet.
class BlessingParticlesPainter extends CustomPainter {
  BlessingParticlesPainter({required this.progress, required this.origin, required this.spread})
    : super(repaint: progress);

  final Animation<double> progress;
  final Offset origin;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0 || p >= 1) return;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 44; i++) {
      final delay = mandirHash(i, 51) * 0.35;
      final local = ((p - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final x = origin.dx + (mandirHash(i, 52) - 0.5) * spread + math.sin(local * 6 + i) * 10;
      final y = origin.dy - Curves.easeOut.transform(local) * size.height * (0.25 + mandirHash(i, 53) * 0.2);
      final fade = math.sin(local * math.pi);
      final r = 1.2 + mandirHash(i, 54) * 2.4;
      paint.color = const Color(0xFFFFC107).withValues(alpha: 0.3 * fade);
      canvas.drawCircle(Offset(x, y), r * 3, paint);
      paint.color = const Color(0xFFFFF8E1).withValues(alpha: 0.95 * fade);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(BlessingParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}

/// Expanding golden rings: Shankh naad from the sanctum, or a bell's ring.
class SoundRipplePainter extends CustomPainter {
  SoundRipplePainter({
    required this.progress,
    required this.center,
    required this.maxRadius,
    this.rings = 5,
    this.squash = 1.0,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Offset center;
  final double maxRadius;
  final int rings;

  /// Vertical squash of each ring (1 = circle).
  final double squash;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p <= 0 || p >= 1) return;
    for (var i = 0; i < rings; i++) {
      final local = ((p - i * 0.12) / 0.6).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final r = Curves.easeOutCubic.transform(local) * maxRadius;
      final fade = 1 - local;
      final rect = Rect.fromCenter(center: center, width: r * 2, height: r * 2 * squash);
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * fade + 1
          ..color = const Color(0xFFFFC75A).withValues(alpha: 0.35 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * fade + 0.4
          ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.85 * fade),
      );
    }
    if (p < 0.25) {
      final flash = 1 - p / 0.25;
      canvas.drawCircle(
        center,
        maxRadius * 0.18,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(center, maxRadius * 0.18, [
            const Color(0xFFFFE9B0).withValues(alpha: 0.5 * flash),
            const Color(0x00FFE9B0),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(SoundRipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.center != center || oldDelegate.maxRadius != maxRadius;
}

// ═══════════════════════════════════════════════════════════════════════════
//  OUTER PLANE: PILLARS, TORAN, BELLS
// ═══════════════════════════════════════════════════════════════════════════

/// Carved sandstone temple pillar.
class TemplePillarPainter extends CustomPainter {
  const TemplePillarPainter({required this.left});

  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [Color(0xFF3A2414), Color(0xFFB98A5A), Color(0xFF8A6038), Color(0xFF2A180C)],
          stops: const [0, 0.45, 0.75, 1],
        ).createShader(rect),
    );
    final carve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF2A180C).withValues(alpha: 0.55);
    final hi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFF2CF95).withValues(alpha: 0.35);
    for (var y = h * 0.04; y < h; y += h * 0.09) {
      canvas.drawLine(Offset(0, y), Offset(w, y), carve);
      canvas.drawLine(Offset(0, y + 2), Offset(w, y + 2), hi);
      final c = Offset(w / 2, y + h * 0.045);
      final r = w * 0.22;
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        canvas.drawOval(
          Rect.fromCenter(center: c + Offset(math.cos(a), math.sin(a)) * r * 0.6, width: r * 0.7, height: r * 0.7),
          carve,
        );
      }
    }
    final edge = Paint()
      ..shader = LinearGradient(
        begin: left ? Alignment.centerRight : Alignment.centerLeft,
        end: left ? Alignment.centerLeft : Alignment.centerRight,
        colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(left ? w * 0.8 : 0, 0, w * 0.2, h));
    canvas.drawRect(Rect.fromLTWH(left ? w * 0.8 : 0, 0, w * 0.2, h), edge);
  }

  @override
  bool shouldRepaint(TemplePillarPainter oldDelegate) => oldDelegate.left != left;
}

/// Festive marigold toran with mango leaves, swaying in the breeze.
class ToranPainter extends CustomPainter {
  ToranPainter(this.clock) : super(repaint: clock);

  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.16),
      Paint()..shader = Brass.body(Rect.fromLTWH(0, 0, w, h * 0.16), vertical: true),
    );
    const swags = 5;
    final bead = h * 0.085;
    for (var s = 0; s < swags; s++) {
      final x0 = w * s / swags;
      final x1 = w * (s + 1) / swags;
      for (var i = 0; i <= 9; i++) {
        final u = i / 9;
        final x = x0 + (x1 - x0) * u;
        final sag = math.sin(u * math.pi) * h * 0.32;
        final p = Offset(x + math.sin(t * 1.2 + s) * 1.5, h * 0.16 + sag);
        canvas.drawCircle(
          p,
          bead,
          Paint()
            ..shader = RadialGradient(
              colors: (i + s).isEven
                  ? const [Color(0xFFFFE082), Color(0xFFFF8F00)]
                  : const [Color(0xFFFFB74D), Color(0xFFE65100)],
            ).createShader(Rect.fromCircle(center: p, radius: bead)),
        );
      }
      final hang = Offset((x0 + x1) / 2, h * 0.5);
      final swing = math.sin(t * 1.6 + s * 1.3) * 0.12;
      canvas.save();
      canvas.translate(hang.dx, hang.dy);
      canvas.rotate(swing);
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(0, bead * 1.6 * i),
          bead * 0.8,
          Paint()..color = i.isEven ? const Color(0xFFFFA000) : const Color(0xFFD32F2F),
        );
      }
      final leafTop = bead * 4;
      final leafLen = bead * 3.6;
      final leaf = Path()
        ..moveTo(0, leafTop)
        ..quadraticBezierTo(bead * 0.9, leafTop + leafLen * 0.45, 0, leafTop + leafLen)
        ..quadraticBezierTo(-bead * 0.9, leafTop + leafLen * 0.45, 0, leafTop)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = ui.Gradient.linear(Offset(-bead, leafTop), Offset(bead, leafTop + leafLen), const [
            Color(0xFF43A047),
            Color(0xFF1B5E20),
          ]),
      );
      canvas.drawLine(
        Offset(0, leafTop),
        Offset(0, leafTop + leafLen),
        Paint()
          ..strokeWidth = 0.7
          ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.7),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ToranPainter oldDelegate) => oldDelegate.clock != clock;
}

/// Brass temple ghanta on a short chain; pivots at the top-centre.
class TempleBellPainter extends CustomPainter {
  const TempleBellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final chain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..shader = Brass.body(rect);
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w / 2, h * (0.05 + i * 0.075)), width: w * 0.14, height: h * 0.085),
        chain,
      );
    }
    final bell = Path()
      ..moveTo(w * 0.42, h * 0.36)
      ..quadraticBezierTo(w * 0.24, h * 0.4, w * 0.24, h * 0.62)
      ..quadraticBezierTo(w * 0.22, h * 0.78, w * 0.08, h * 0.86)
      ..lineTo(w * 0.92, h * 0.86)
      ..quadraticBezierTo(w * 0.78, h * 0.78, w * 0.76, h * 0.62)
      ..quadraticBezierTo(w * 0.76, h * 0.4, w * 0.58, h * 0.36)
      ..close();
    canvas.drawPath(bell, Paint()..shader = Brass.body(rect));
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Brass.deep.withValues(alpha: 0.55);
    canvas.drawLine(Offset(w * 0.25, h * 0.52), Offset(w * 0.75, h * 0.52), band);
    canvas.drawLine(Offset(w * 0.2, h * 0.76), Offset(w * 0.8, h * 0.76), band);
    final lip = Rect.fromLTWH(w * 0.06, h * 0.83, w * 0.88, h * 0.06);
    canvas.drawOval(lip, Paint()..shader = Brass.body(lip));
    final clapper = Offset(w / 2, h * 0.93);
    canvas.drawCircle(clapper, w * 0.07, Paint()..shader = Brass.dome(clapper, w * 0.07));
  }

  @override
  bool shouldRepaint(TempleBellPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  SEVA RAIL ICONS
// ═══════════════════════════════════════════════════════════════════════════

enum SevaIcon { ghee, aarti, pushpanjali, ghanta, shankh, tilak, charan, naivedya, changeDeity }

/// Gold line-and-fill ritual glyphs for the seva medallions.
class SevaIconPainter extends CustomPainter {
  const SevaIconPainter(this.icon);

  final SevaIcon icon;

  static const _flameColors = [Color(0xFFFFF59D), Color(0xFFFF9800), Color(0xFFE65100)];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & size;
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF1C1), Color(0xFFE2B33C), Color(0xFFB07A1E)],
      ).createShader(rect);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gold.shader;

    switch (icon) {
      case SevaIcon.ghee:
        final body = Path()
          ..moveTo(s * 0.44, s * 0.3)
          ..cubicTo(s * 0.2, s * 0.38, s * 0.22, s * 0.86, s * 0.58, s * 0.86)
          ..cubicTo(s * 0.94, s * 0.86, s * 0.96, s * 0.38, s * 0.72, s * 0.3)
          ..close();
        canvas.drawPath(body, gold);
        canvas.drawLine(Offset(s * 0.4, s * 0.24), Offset(s * 0.76, s * 0.24), line);
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.34, s * 0.56)
            ..quadraticBezierTo(s * 0.2, s * 0.5, s * 0.1, s * 0.34),
          line,
        );
        _drop(canvas, Offset(s * 0.1, s * 0.56), s * 0.09, const Color(0xFFFFC107));
        canvas.drawArc(
          Rect.fromCenter(center: Offset(s * 0.58, s * 0.6), width: s * 0.22, height: s * 0.14),
          math.pi,
          math.pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.03
            ..color = const Color(0xFF7A5414),
        );
      case SevaIcon.aarti:
        final plate = Rect.fromCenter(center: Offset(s * 0.5, s * 0.74), width: s * 0.86, height: s * 0.3);
        canvas.drawOval(plate, gold);
        canvas.drawOval(
          plate.deflate(s * 0.06),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.025
            ..color = const Color(0xFF7A5414),
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(s * 0.5, s * 0.6), width: s * 0.32, height: s * 0.2),
          0,
          math.pi,
          true,
          gold,
        );
        _flame(canvas, Offset(s * 0.5, s * 0.58), s * 0.4, s * 0.2);
      case SevaIcon.pushpanjali:
        final c = Offset(s * 0.5, s * 0.58);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * math.pi * 2 / 5;
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(a + math.pi / 2);
          final petal = Rect.fromCenter(center: Offset(0, -s * 0.16), width: s * 0.2, height: s * 0.3);
          canvas.drawOval(
            petal,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              ).createShader(petal),
          );
          canvas.restore();
        }
        canvas.drawCircle(c, s * 0.08, Paint()..color = const Color(0xFFB34700));
        for (final (o, r) in [
          (Offset(s * 0.16, s * 0.18), 0.06),
          (Offset(s * 0.84, s * 0.12), 0.05),
          (Offset(s * 0.78, s * 0.3), 0.04),
        ]) {
          _drop(canvas, o, s * r, const Color(0xFFFF5C7A));
        }
      case SevaIcon.ghanta:
        canvas.drawCircle(Offset(s * 0.5, s * 0.14), s * 0.06, line);
        final bell = Path()
          ..moveTo(s * 0.42, s * 0.22)
          ..quadraticBezierTo(s * 0.28, s * 0.26, s * 0.28, s * 0.5)
          ..quadraticBezierTo(s * 0.26, s * 0.66, s * 0.16, s * 0.72)
          ..lineTo(s * 0.84, s * 0.72)
          ..quadraticBezierTo(s * 0.74, s * 0.66, s * 0.72, s * 0.5)
          ..quadraticBezierTo(s * 0.72, s * 0.26, s * 0.58, s * 0.22)
          ..close();
        canvas.drawPath(bell, gold);
        canvas.drawCircle(Offset(s * 0.5, s * 0.8), s * 0.07, gold);
        for (final dir in const [-1.0, 1.0]) {
          for (var i = 0; i < 2; i++) {
            final r = s * (0.12 + i * 0.1);
            canvas.drawArc(
              Rect.fromCircle(center: Offset(s * 0.5 + dir * s * 0.34, s * 0.5), radius: r),
              dir > 0 ? -0.6 : math.pi - 0.6,
              1.2,
              false,
              line..strokeWidth = s * 0.045,
            );
          }
        }
      case SevaIcon.shankh:
        final shell = Path()
          ..moveTo(s * 0.12, s * 0.62)
          ..cubicTo(s * 0.1, s * 0.3, s * 0.5, s * 0.16, s * 0.68, s * 0.34)
          ..cubicTo(s * 0.8, s * 0.46, s * 0.72, s * 0.7, s * 0.5, s * 0.74)
          ..quadraticBezierTo(s * 0.3, s * 0.78, s * 0.12, s * 0.62)
          ..close();
        canvas.drawPath(
          shell,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFDF5), Color(0xFFF3DDB8), Color(0xFFD6B47E)],
            ).createShader(rect),
        );
        final spiral = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.035
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFB07A1E);
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(s * 0.48, s * 0.5), radius: s * (0.06 + i * 0.07)),
            -math.pi * 0.2 + i,
            math.pi * 1.1,
            false,
            spiral,
          );
        }
        canvas.drawPath(shell, line..strokeWidth = s * 0.04);
        for (var i = 0; i < 2; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(s * 0.72, s * 0.5), radius: s * (0.16 + i * 0.1)),
            -0.5,
            1.0,
            false,
            line..strokeWidth = s * 0.045,
          );
        }
      case SevaIcon.tilak:
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.3, s * 0.14)
            ..quadraticBezierTo(s * 0.28, s * 0.8, s * 0.5, s * 0.84)
            ..quadraticBezierTo(s * 0.72, s * 0.8, s * 0.7, s * 0.14),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = s * 0.1
            ..color = const Color(0xFFFFE9B0),
        );
        final drop = Path()
          ..moveTo(s * 0.5, s * 0.2)
          ..quadraticBezierTo(s * 0.6, s * 0.52, s * 0.5, s * 0.68)
          ..quadraticBezierTo(s * 0.4, s * 0.52, s * 0.5, s * 0.2)
          ..close();
        canvas.drawPath(
          drop,
          Paint()
            ..color = const Color(0xFFFF1744)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
        );
      case SevaIcon.charan:
        for (final (dx, dy, mirror) in [(0.32, 0.56, -1.0), (0.66, 0.44, 1.0)]) {
          final c = Offset(s * dx, s * dy);
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(mirror * 0.12);
          canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.08), width: s * 0.2, height: s * 0.36), gold);
          for (var t = 0; t < 5; t++) {
            final tx = (t - 2) * s * 0.05 * mirror;
            final ty = -s * 0.15 - (2 - (t - 2).abs()) * s * 0.025;
            canvas.drawCircle(Offset(tx, ty), s * (t == (mirror > 0 ? 0 : 4) ? 0.04 : 0.03), gold);
          }
          canvas.restore();
        }
        canvas.drawCircle(Offset(s * 0.5, s * 0.14), s * 0.04, Paint()..color = const Color(0xFFFF1744));
      case SevaIcon.naivedya:
        final plate = Rect.fromCenter(center: Offset(s * 0.5, s * 0.76), width: s * 0.9, height: s * 0.26);
        canvas.drawOval(plate, gold);
        final modak = Path()
          ..moveTo(s * 0.42, s * 0.2)
          ..cubicTo(s * 0.48, s * 0.36, s * 0.66, s * 0.48, s * 0.6, s * 0.72)
          ..lineTo(s * 0.24, s * 0.72)
          ..cubicTo(s * 0.18, s * 0.48, s * 0.36, s * 0.36, s * 0.42, s * 0.2)
          ..close();
        canvas.drawPath(modak, Paint()..color = const Color(0xFFFFF8E7));
        final ridge = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.025
          ..color = const Color(0xFFC9A877);
        for (var r = -1; r <= 1; r++) {
          canvas.drawLine(Offset(s * 0.42, s * 0.24), Offset(s * (0.42 + r * 0.1), s * 0.7), ridge);
        }
        final ladoo = Offset(s * 0.72, s * 0.6);
        canvas.drawCircle(
          ladoo,
          s * 0.13,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.3, -0.4),
              colors: [Color(0xFFFFCC80), Color(0xFFF57C00), Color(0xFFB34700)],
            ).createShader(Rect.fromCircle(center: ladoo, radius: s * 0.13)),
        );
      case SevaIcon.changeDeity:
        final shikhara = Path()
          ..moveTo(s * 0.37, s * 0.68)
          ..quadraticBezierTo(s * 0.38, s * 0.44, s * 0.5, s * 0.3)
          ..quadraticBezierTo(s * 0.62, s * 0.44, s * 0.63, s * 0.68)
          ..close();
        canvas.drawPath(shikhara, gold);
        canvas.drawRect(Rect.fromLTRB(s * 0.33, s * 0.67, s * 0.67, s * 0.73), gold);
        canvas.drawLine(Offset(s * 0.5, s * 0.3), Offset(s * 0.5, s * 0.2), line..strokeWidth = s * 0.04);
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.5, s * 0.2)
            ..lineTo(s * 0.6, s * 0.23)
            ..lineTo(s * 0.5, s * 0.26)
            ..close(),
          Paint()..color = const Color(0xFFFF6D00),
        );
        canvas.drawPath(
          Path()
            ..moveTo(s * 0.5, s * 0.48)
            ..quadraticBezierTo(s * 0.55, s * 0.56, s * 0.5, s * 0.67)
            ..quadraticBezierTo(s * 0.45, s * 0.56, s * 0.5, s * 0.48)
            ..close(),
          Paint()..color = const Color(0xFF7A1E05),
        );
        final c = Offset(s * 0.5, s * 0.5);
        final r = s * 0.44;
        final arrow = line..strokeWidth = s * 0.06;
        for (final start in const [-2.7, 0.44]) {
          const sweep = 2.0;
          canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, arrow);
          final end = start + sweep;
          final tip = c + Offset(math.cos(end), math.sin(end)) * r;
          final dir = Offset(-math.sin(end), math.cos(end));
          final side = Offset(-dir.dy, dir.dx);
          final back = tip - dir * (s * 0.14);
          canvas.drawLine(tip, back + side * (s * 0.08), arrow);
          canvas.drawLine(tip, back - side * (s * 0.08), arrow);
        }
    }
  }

  static void _flame(Canvas canvas, Offset base, double h, double w) {
    final tip = base.translate(0, -h);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - w, base.dy - h * 0.2, tip.dx - w * 0.4, tip.dy + h * 0.5, tip.dx, tip.dy)
      ..cubicTo(tip.dx + w * 0.4, tip.dy + h * 0.5, base.dx + w, base.dy - h * 0.2, base.dx, base.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(tip, base, _flameColors, const [0, 0.55, 1])
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );
  }

  static void _drop(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 1.6)
        ..quadraticBezierTo(c.dx + r * 1.2, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * 1.2, c.dy, c.dx, c.dy - r * 1.6)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(SevaIconPainter oldDelegate) => oldDelegate.icon != icon;
}
