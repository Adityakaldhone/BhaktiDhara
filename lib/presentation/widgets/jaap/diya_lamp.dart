import 'package:flutter/material.dart';

const String _diyaAsset = 'assets/aarti_screen/deepak.png';

const ColorFilter _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 0.45, 0,
]);

/// The streak diya. Lit when [lit]; optionally flickers gently.
///
/// Keep [flicker] off on screens covered by `pumpAndSettle` tests (it repeats
/// forever) and it is skipped automatically when the OS asks to reduce motion.
class DiyaLamp extends StatefulWidget {
  final double size;
  final bool lit;
  final bool flicker;

  const DiyaLamp({
    super.key,
    this.size = 40,
    this.lit = true,
    this.flicker = false,
  });

  @override
  State<DiyaLamp> createState() => _DiyaLampState();
}

class _DiyaLampState extends State<DiyaLamp>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(DiyaLamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shouldAnimate = widget.flicker && widget.lit && !reduceMotion;
    if (shouldAnimate && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!shouldAnimate && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      _diyaAsset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Text(
        '🪔',
        style: TextStyle(fontSize: widget.size * 0.8),
      ),
    );
    if (!widget.lit) {
      return ColorFiltered(colorFilter: _greyscale, child: image);
    }
    final controller = _controller;
    if (controller == null) return image;
    return AnimatedBuilder(
      animation: controller,
      child: image,
      builder: (context, child) => Transform.scale(
        scaleY: 0.97 + 0.06 * Curves.easeInOut.transform(controller.value),
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );
  }
}
