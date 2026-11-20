import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/jaap_progress.dart';
import '../../jaap/jaap_colors.dart';

/// A 108-bead mala drawn around a circle with the Sumeru (guru) bead at the
/// top. Counted beads glow warm; the most recent bead pulses on each tap.
///
/// Alternate malas run in the opposite direction, because traditionally the
/// Sumeru bead is never crossed — the mala is turned around instead.
class MalaRing extends StatelessWidget {
  final int beadIndex;
  final int malaNumber;

  /// 0 → 1 on every tap.
  final Animation<double> pulse;

  /// 0 → 1 → 0 when a mala completes.
  final Animation<double> glow;

  final Widget? center;

  const MalaRing({
    super.key,
    required this.beadIndex,
    required this.malaNumber,
    required this.pulse,
    required this.glow,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _MalaPainter(
          beadIndex: beadIndex,
          clockwise: malaNumber.isEven,
          pulse: pulse,
          glow: glow,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _MalaPainter extends CustomPainter {
  static const int _beads = JaapProgress.beadsPerMala;
  static const int _slots = _beads + 1;

  final int beadIndex;
  final bool clockwise;
  final Animation<double> pulse;
  final Animation<double> glow;

  _MalaPainter({
    required this.beadIndex,
    required this.clockwise,
    required this.pulse,
    required this.glow,
  }) : super(repaint: Listenable.merge([pulse, glow]));

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outerMargin = size.width * 0.09;
    final r = size.width / 2 - outerMargin;
    final beadR = math.min(r * math.pi / _slots * 0.9, 7.2);
    final step = 2 * math.pi / _slots;
    final dir = clockwise ? 1.0 : -1.0;
    const top = -math.pi / 2;

    final g = glow.value;
    if (g > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = JaapColors.glowGold.withValues(alpha: 0.9 * g)
          ..style = PaintingStyle.stroke
          ..strokeWidth = beadR * 7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = JaapColors.thread.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05,
    );

    final current = beadIndex - 1;
    final p = Curves.easeOut.transform(pulse.value);
    for (var i = 0; i < _beads; i++) {
      final angle = top + dir * (i + 1) * step;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * r;
      final counted = i < beadIndex;
      var radius = beadR;
      if (i == current) {
        radius = beadR * (1.35 + 0.55 * math.sin(p * math.pi));
        canvas.drawCircle(
          pos,
          radius * 2.6,
          Paint()
            ..color = JaapColors.glowGold.withValues(alpha: 0.65)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      _drawBead(
        canvas,
        pos,
        radius,
        counted ? JaapColors.beadDone : JaapColors.beadRudraksha,
        warm: counted,
      );
    }

    _drawSumeru(canvas, c + Offset(0, -r), beadR);
  }

  void _drawBead(
    Canvas canvas,
    Offset pos,
    double radius,
    Color base, {
    bool warm = false,
  }) {
    final rect = Rect.fromCircle(center: pos, radius: radius);
    if (warm) {
      canvas.drawCircle(
        pos,
        radius * 1.55,
        Paint()
          ..color = JaapColors.glowGold.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.05,
          colors: [
            Color.lerp(base, Colors.white, warm ? 0.55 : 0.4)!,
            base,
            Color.lerp(base, Colors.black, warm ? 0.28 : 0.38)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(rect),
    );
    // Specular highlight for a more physical bead.
    canvas.drawCircle(
      pos + Offset(-radius * 0.28, -radius * 0.32),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: warm ? 0.45 : 0.28),
    );
  }

  void _drawSumeru(Canvas canvas, Offset pos, double beadR) {
    final tasselPaint = Paint()
      ..color = JaapColors.thread.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final knot = pos + Offset(0, -beadR * 2.7);
    for (var k = -3; k <= 3; k++) {
      final end = knot + Offset(k * beadR * 0.55, -beadR * 3.3);
      canvas.drawLine(knot, end, tasselPaint);
    }
    canvas.drawCircle(
      knot,
      beadR * 0.95,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(JaapColors.sumeru, Colors.white, 0.25)!,
            JaapColors.sumeru,
          ],
        ).createShader(Rect.fromCircle(center: knot, radius: beadR * 0.95)),
    );

    final radius = beadR * 2.25;
    canvas.drawCircle(
      pos,
      radius * 1.7,
      Paint()
        ..color = JaapColors.glowGold.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    _drawBead(canvas, pos, radius, JaapColors.sumeru, warm: true);
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = JaapColors.thread
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(_MalaPainter old) =>
      old.beadIndex != beadIndex || old.clockwise != clockwise;
}
