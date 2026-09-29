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
    final beadR = math.min(r * math.pi / _slots * 0.9, 7.0);
    final step = 2 * math.pi / _slots;
    final dir = clockwise ? 1.0 : -1.0;
    const top = -math.pi / 2;

    final g = glow.value;
    if (g > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = JaapColors.glowGold.withValues(alpha: 0.85 * g)
          ..style = PaintingStyle.stroke
          ..strokeWidth = beadR * 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = JaapColors.thread.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final current = beadIndex - 1;
    final p = Curves.easeOut.transform(pulse.value);
    for (var i = 0; i < _beads; i++) {
      final angle = top + dir * (i + 1) * step;
      final pos = c + Offset(math.cos(angle), math.sin(angle)) * r;
      final counted = i < beadIndex;
      var radius = beadR;
      if (i == current) {
        radius = beadR * (1.25 + 0.45 * math.sin(p * math.pi));
        canvas.drawCircle(
          pos,
          radius * 2.2,
          Paint()
            ..color = JaapColors.glowGold.withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      _drawBead(
        canvas,
        pos,
        radius,
        counted ? JaapColors.beadDone : JaapColors.beadRudraksha,
      );
    }

    _drawSumeru(canvas, c + Offset(0, -r), beadR);
  }

  void _drawBead(Canvas canvas, Offset pos, double radius, Color base) {
    final rect = Rect.fromCircle(center: pos, radius: radius);
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 1.0,
          colors: [
            Color.lerp(base, Colors.white, 0.45)!,
            base,
            Color.lerp(base, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
  }

  void _drawSumeru(Canvas canvas, Offset pos, double beadR) {
    final tasselPaint = Paint()
      ..color = JaapColors.thread
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final knot = pos + Offset(0, -beadR * 2.6);
    for (var k = -3; k <= 3; k++) {
      final end = knot + Offset(k * beadR * 0.55, -beadR * 3.2);
      canvas.drawLine(knot, end, tasselPaint);
    }
    canvas.drawCircle(knot, beadR * 0.9, Paint()..color = JaapColors.sumeru);

    final radius = beadR * 2.1;
    canvas.drawCircle(
      pos,
      radius * 1.5,
      Paint()
        ..color = JaapColors.glowGold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    _drawBead(canvas, pos, radius, JaapColors.sumeru);
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = JaapColors.thread
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_MalaPainter old) =>
      old.beadIndex != beadIndex || old.clockwise != clockwise;
}
