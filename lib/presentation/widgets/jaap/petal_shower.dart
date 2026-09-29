import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pushpa (flower) petals falling over the screen for ~2 seconds each time
/// [trigger] changes. Skipped when the OS asks to reduce motion.
class PetalShower extends StatefulWidget {
  final int trigger;

  const PetalShower({super.key, required this.trigger});

  @override
  State<PetalShower> createState() => _PetalShowerState();
}

class _Petal {
  final double x;
  final double size;
  final double delay;
  final double sway;
  final double spin;

  const _Petal(this.x, this.size, this.delay, this.sway, this.spin);
}

class _PetalShowerState extends State<PetalShower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  List<_Petal> _petals = const [];

  @override
  void didUpdateWidget(PetalShower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) return;
      final rnd = math.Random(widget.trigger);
      _petals = List.generate(
        16,
        (_) => _Petal(
          rnd.nextDouble(),
          18 + rnd.nextDouble() * 16,
          rnd.nextDouble() * 0.35,
          (rnd.nextDouble() - 0.5) * 60,
          (rnd.nextDouble() - 0.5) * 4,
        ),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!_controller.isAnimating || _petals.isEmpty) {
            return const SizedBox.expand();
          }
          final size = MediaQuery.sizeOf(context);
          return Stack(
            children: [
              for (final petal in _petals) _buildPetal(petal, size),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPetal(_Petal petal, Size size) {
    final t = ((_controller.value - petal.delay) / (1 - petal.delay))
        .clamp(0.0, 1.0);
    if (t == 0) return const SizedBox.shrink();
    final y = -40 + t * (size.height * 0.75);
    final x = petal.x * size.width + math.sin(t * math.pi * 2) * petal.sway;
    final opacity = t < 0.8 ? 1.0 : (1 - t) / 0.2;
    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: petal.spin * t * math.pi,
          child: Image.asset(
            'assets/aarti_screen/pushpa.png',
            width: petal.size,
            height: petal.size,
            errorBuilder: (_, _, _) => Text(
              '🌸',
              style: TextStyle(fontSize: petal.size),
            ),
          ),
        ),
      ),
    );
  }
}
