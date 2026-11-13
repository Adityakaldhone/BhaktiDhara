import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Looping Akhand Jyot animations are off under `flutter test`, where they
/// would keep `pumpAndSettle` from ever settling.
final bool jyotAnimationsEnabled =
    kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

/// Brass diya with a living flame. [intensity] scales the flame (1.0 bright,
/// 0.75 medium, 0.45 low); 0 shows an unlit wick with rising smoke.
class JyotFlame extends StatefulWidget {
  const JyotFlame({
    super.key,
    required this.size,
    required this.intensity,
    this.flicker = false,
  });

  final double size;
  final double intensity;

  /// Uneven, nervous flicker for a diya that is running out of ghee.
  final bool flicker;

  @override
  State<JyotFlame> createState() => _JyotFlameState();
}

class _JyotFlameState extends State<JyotFlame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    value: 0.3,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = jyotAnimationsEnabled && !MediaQuery.of(context).disableAnimations;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _DiyaPainter(
          time: _controller,
          intensity: widget.intensity,
          flicker: widget.flicker,
        ),
      ),
    );
  }
}

class _DiyaPainter extends CustomPainter {
  _DiyaPainter({required this.time, required this.intensity, required this.flicker})
      : super(repaint: time);

  final Animation<double> time;
  final double intensity;
  final bool flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final rimY = h * 0.70;
    final t = time.value * 2 * math.pi;

    // Foot of the samai.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.95), width: w * 0.42, height: h * 0.07),
      Paint()..color = const Color(0xFF9A6A1C),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, h * 0.89), width: w * 0.1, height: h * 0.1),
      Paint()..color = const Color(0xFFB8862B),
    );

    // Bowl.
    final bowl = Path()
      ..moveTo(cx - w * 0.38, rimY)
      ..quadraticBezierTo(cx, h * 1.0, cx + w * 0.38, rimY)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE08A), Color(0xFFD4A03A), Color(0xFF8C5A12)],
        ).createShader(Rect.fromLTWH(cx - w * 0.38, rimY, w * 0.76, h * 0.2)),
    );
    // Ghee surface.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimY), width: w * 0.76, height: h * 0.07),
      Paint()..color = const Color(0xFF7A4A0E),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimY), width: w * 0.66, height: h * 0.045),
      Paint()..color = const Color(0xFFE8B54A),
    );

    // Wick.
    final wickTop = Offset(cx, rimY - h * 0.07);
    canvas.drawLine(
      Offset(cx, rimY),
      wickTop,
      Paint()
        ..color = const Color(0xFF3E2A14)
        ..strokeWidth = math.max(1.2, w * 0.035)
        ..strokeCap = StrokeCap.round,
    );

    if (intensity <= 0.01) {
      _paintSmoke(canvas, wickTop, w, h);
      return;
    }

    final jitter = flicker
        ? 0.10 * math.sin(t * 7) + 0.06 * math.sin(t * 13 + 1)
        : 0.04 * math.sin(t * 3);
    final sway = w * (flicker ? 0.05 : 0.025) * math.sin(t * (flicker ? 5 : 2));
    final fh = h * 0.56 * intensity * (1 + jitter);
    final fw = w * 0.17 * (0.6 + 0.4 * intensity);
    final base = wickTop.translate(0, h * 0.02);
    final tip = Offset(cx + sway, base.dy - fh);

    // Glow.
    final glowCenter = Offset(cx, base.dy - fh * 0.45);
    final glowR = fh * 0.95 + w * 0.06;
    canvas.drawCircle(
      glowCenter,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFC107).withValues(alpha: 0.55 * intensity),
            const Color(0xFFFF8F00).withValues(alpha: 0.18 * intensity),
            const Color(0x00FF8F00),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowR)),
    );

    Path flame(double scale) {
      final s = fh * scale;
      final sw = fw * scale;
      final top = Offset(cx + sway * scale, base.dy - s);
      return Path()
        ..moveTo(cx, base.dy)
        ..cubicTo(cx - sw * 1.3, base.dy - s * 0.12, cx - sw * 0.5 + sway * 0.4, base.dy - s * 0.7, top.dx, top.dy)
        ..cubicTo(cx + sw * 0.5 + sway * 0.4, base.dy - s * 0.7, cx + sw * 1.3, base.dy - s * 0.12, cx, base.dy)
        ..close();
    }

    final flameRect = Rect.fromPoints(tip, base.translate(0, 1)).inflate(fw * 1.4);
    canvas.drawPath(
      flame(1.0),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFE65100), Color(0xFFFF9800), Color(0xFFFFD54F)],
        ).createShader(flameRect),
    );
    canvas.drawPath(
      flame(0.55),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFFFF59D), Color(0xFFFFFDE7)],
        ).createShader(flameRect),
    );
  }

  void _paintSmoke(Canvas canvas, Offset from, double w, double h) {
    canvas.drawCircle(from, w * 0.025, Paint()..color = const Color(0xFFBF360C));
    for (var i = 0; i < 3; i++) {
      final p = (time.value + i / 3) % 1.0;
      final y = from.dy - p * h * 0.6;
      final x = from.dx + math.sin(p * 2 * math.pi + i) * w * 0.07;
      canvas.drawCircle(
        Offset(x, y),
        w * (0.03 + 0.06 * p),
        Paint()..color = const Color(0xFF8D8D8D).withValues(alpha: 0.45 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_DiyaPainter old) =>
      old.intensity != intensity || old.flicker != flicker;
}
