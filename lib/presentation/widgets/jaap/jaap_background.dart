import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../jaap/jaap_colors.dart';

/// Warm sandalwood gradient with a slowly turning mandala and a faint deity
/// portrait. Rotation stops when the OS asks to reduce motion.
class JaapBackground extends StatefulWidget {
  final String deity;
  final Widget child;

  const JaapBackground({super.key, required this.deity, required this.child});

  @override
  State<JaapBackground> createState() => _JaapBackgroundState();
}

class _JaapBackgroundState extends State<JaapBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 120),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _rotation.stop();
    } else if (!_rotation.isAnimating) {
      _rotation.repeat();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mandalaSize = size.width * 1.2;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final mandala = const RepaintBoundary(
      child: CustomPaint(painter: _MandalaPainter()),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.15,
          colors: [
            Color(0xFFFFF8E8),
            JaapColors.sandalStart,
            JaapColors.sandalEnd,
            Color(0xFFE6CFA0),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: (size.width - mandalaSize) / 2,
            top: size.height * 0.38 - mandalaSize / 2,
            width: mandalaSize,
            height: mandalaSize,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: reduceMotion
                    ? mandala
                    : RotationTransition(turns: _rotation, child: mandala),
              ),
            ),
          ),
          // Soft vignette so the mala and count stay readable.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.05),
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      JaapColors.sandalDeep.withValues(alpha: 0.18),
                      const Color(0xFF8A5A2B).withValues(alpha: 0.12),
                    ],
                    stops: const [0.45, 0.82, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, 0.98),
                child: Image.asset(
                  MandirTheme.getDeityImageAsset(widget.deity),
                  height: size.height * 0.38,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.11),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _MandalaPainter extends CustomPainter {
  const _MandalaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    final stroke = Paint()
      ..color = MandirTheme.goldenAccent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var ring = 1; ring <= 5; ring++) {
      final ringR = maxR * ring / 5.4;
      final petals = 8 * ring;
      final petalLen = maxR / 7;
      for (var i = 0; i < petals; i++) {
        final a = 2 * math.pi * i / petals;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(a);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(ringR, 0),
            width: petalLen,
            height: petalLen * 0.42,
          ),
          stroke,
        );
        canvas.restore();
      }
      canvas.drawCircle(c, ringR - petalLen / 2, stroke);
    }
  }

  @override
  bool shouldRepaint(_MandalaPainter oldDelegate) => false;
}
