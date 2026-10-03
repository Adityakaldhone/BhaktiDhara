import 'package:flutter/material.dart';

import '../../../domain/entities/bhakti_deity.dart';

/// Golden mandap with the selected deity seated inside, behind the pillars and diyas.
class DarshanShrine extends StatefulWidget {
  final BhaktiDeity deity;
  final double width;

  /// -1 when moving to the previous deity, 1 for the next one.
  final int direction;

  const DarshanShrine({
    super.key,
    required this.deity,
    required this.width,
    required this.direction,
  });

  static const frameAsset = 'assets/bhakti/mandap_frame.png';

  @override
  State<DarshanShrine> createState() => _DarshanShrineState();
}

class _DarshanShrineState extends State<DarshanShrine> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 1.5;
    // The arch opening in mandap_frame.png spans ~21%–79% horizontally and its pedestal top sits ~18% from the bottom.
    final deityWidth = w * 0.57;
    final deityHeight = deityWidth * 1.5;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: w * 0.16,
            right: w * 0.16,
            top: h * 0.2,
            height: h * 0.56,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD678).withValues(alpha: 0.8 + 0.15 * _glow.value),
                        const Color(0xFFFFAA3C).withValues(alpha: 0.4 + 0.15 * _glow.value),
                        const Color(0x00FF8C28),
                      ],
                      stops: const [0.0, 0.38, 0.72],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: (w - deityWidth) / 2,
            width: deityWidth,
            bottom: h * 0.185,
            height: deityHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey(widget.deity.key);
                final dx = 0.18 * widget.direction * (isIncoming ? 1 : -1);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                    child: ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                );
              },
              child: Image.asset(
                widget.deity.imageAsset,
                key: ValueKey(widget.deity.key),
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                DarshanShrine.frameAsset,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
