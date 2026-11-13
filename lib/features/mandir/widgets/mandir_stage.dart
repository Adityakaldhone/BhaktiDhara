import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Shares one animation clock (seconds since the sanctum opened) with every
/// painter, so flames, smoke and light move without rebuilding the scene.
class MandirClockScope extends InheritedWidget {
  const MandirClockScope({super.key, required this.clock, required super.child});

  final ValueListenable<double> clock;

  static ValueListenable<double> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MandirClockScope>();
    assert(scope != null, 'No MandirClockScope above this widget');
    return scope!.clock;
  }

  @override
  bool updateShouldNotify(MandirClockScope oldWidget) => clock != oldWidget.clock;
}

/// Flat Garbhagriha stage: runs the animation clock and opens with the
/// Mandir Dwar swinging inwards while the devotee steps in.
class MandirStage extends StatefulWidget {
  const MandirStage({super.key, required this.child});

  final Widget child;

  @override
  State<MandirStage> createState() => _MandirStageState();
}

class _MandirStageState extends State<MandirStage> with TickerProviderStateMixin {
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker((elapsed) => _clock.value = elapsed.inMicroseconds / 1e6);
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entrance.addStatusListener((status) {
      if (status == AnimationStatus.completed) HapticFeedback.selectionClick();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _ticker.start();
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1;
    } else {
      HapticFeedback.heavyImpact();
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _entrance.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MandirClockScope(
      clock: _clock,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF140604)),
            AnimatedBuilder(
              animation: _entrance,
              child: widget.child,
              builder: (context, child) =>
                  Transform.scale(scale: 0.84 + 0.16 * Curves.easeOutCubic.transform(_entrance.value), child: child),
            ),
            AnimatedBuilder(
              animation: _entrance,
              builder: (context, _) => _entrance.isCompleted
                  ? const SizedBox.shrink()
                  : IgnorePointer(child: MandirDwar(progress: _entrance.value)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carved teakwood temple doors with brass studs, swinging inwards on their
/// outer hinges as [progress] runs 0 → 1.
class MandirDwar extends StatelessWidget {
  const MandirDwar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final open = Curves.easeInOutCubic.transform(((progress - 0.08) / 0.92).clamp(0.0, 1.0));
    final angle = open * 1.42;
    final fade = progress < 0.85 ? 1.0 : (1 - (progress - 0.85) / 0.15).clamp(0.0, 1.0);

    Widget door(bool left) => Transform(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateY(left ? -angle : angle),
      child: CustomPaint(
        painter: _TeakDoorPainter(left: left),
        size: Size.infinite,
      ),
    );

    return Opacity(
      opacity: fade,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Darkness of the closed mandap lifts as the doors part.
          ColoredBox(color: Colors.black.withValues(alpha: (1 - open) * 0.55)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: door(true)),
              Expanded(child: door(false)),
            ],
          ),
          // Sliver of lamplight escaping through the seam.
          if (open < 0.35)
            Center(
              child: Container(
                width: 6 + open * 120,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC75A).withValues(alpha: 0.75 * (1 - open / 0.35)),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeakDoorPainter extends CustomPainter {
  _TeakDoorPainter({required this.left});

  final bool left;

  static const _teakDark = Color(0xFF3B1F0E);
  static const _teak = Color(0xFF6B3A1C);
  static const _teakLight = Color(0xFF8E5328);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: left ? Alignment.centerLeft : Alignment.centerRight,
          end: left ? Alignment.centerRight : Alignment.centerLeft,
          colors: const [_teakDark, _teak, _teakLight, _teak],
          stops: const [0, 0.35, 0.8, 1],
        ).createShader(rect),
    );

    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _teakDark.withValues(alpha: 0.35);
    for (var i = 0; i < 26; i++) {
      final x = size.width * (i + 0.5) / 26;
      final path = Path()..moveTo(x, 0);
      for (var y = 0.0; y <= size.height; y += 24) {
        path.lineTo(x + math.sin(y / 70 + i * 1.7) * 3.2, y);
      }
      canvas.drawPath(path, grain);
    }

    final margin = size.width * 0.12;
    final panelW = size.width - margin * 2;
    final panelGap = size.height * 0.035;
    final panelH = (size.height - margin * 2 - panelGap * 2) / 3;
    for (var row = 0; row < 3; row++) {
      final r = Rect.fromLTWH(margin, margin + row * (panelH + panelGap), panelW, panelH);
      _panel(canvas, r);
    }

    final studR = size.width * 0.022;
    final studStep = size.height / 18;
    for (var y = studStep / 2; y < size.height; y += studStep) {
      _stud(canvas, Offset(margin * 0.5, y), studR);
      _stud(canvas, Offset(size.width - margin * 0.5, y), studR);
    }
    final railYs = [
      margin * 0.5,
      for (var row = 1; row < 3; row++) margin + row * (panelH + panelGap) - panelGap / 2,
      size.height - margin * 0.5,
    ];
    for (final y in railYs) {
      for (var x = margin; x <= size.width - margin + 0.1; x += panelW / 6) {
        _stud(canvas, Offset(x, y), studR * 0.9);
      }
    }

    final hingeX = left ? 0.0 : size.width;
    final strap = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8A6018), Color(0xFFE9C46A), Color(0xFF8A6018)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 12));
    for (final fy in const [0.16, 0.84]) {
      final y = size.height * fy;
      final w = size.width * 0.42;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left ? hingeX : hingeX - w, y - 6, w, 12), const Radius.circular(6)),
        strap,
      );
    }

    final seamX = left ? size.width - margin * 0.9 : margin * 0.9;
    final ringC = Offset(seamX, size.height * 0.5);
    final ringR = size.width * 0.07;
    canvas.drawCircle(
      ringC,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringR * 0.28
        ..shader = const SweepGradient(
          colors: [Color(0xFFFFE7A0), Color(0xFF9A6B1C), Color(0xFFFFE7A0), Color(0xFF9A6B1C), Color(0xFFFFE7A0)],
        ).createShader(Rect.fromCircle(center: ringC, radius: ringR)),
    );
    _stud(canvas, ringC.translate(0, -ringR), ringR * 0.45);
  }

  void _panel(Canvas canvas, Rect r) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.06));
    canvas.drawRRect(rr, Paint()..color = _teakDark.withValues(alpha: 0.45));
    canvas.drawRRect(
      rr.deflate(r.width * 0.05),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_teakLight.withValues(alpha: 0.9), _teak, _teakDark.withValues(alpha: 0.9)],
        ).createShader(r),
    );
    final c = r.center;
    final petal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFD9A54A).withValues(alpha: 0.75);
    final rad = math.min(r.width, r.height) * 0.28;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final tip = c + Offset(math.cos(a), math.sin(a)) * rad;
      final side = Offset(-math.sin(a), math.cos(a)) * rad * 0.28;
      final mid = c + Offset(math.cos(a), math.sin(a)) * rad * 0.5;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..quadraticBezierTo((mid + side).dx, (mid + side).dy, tip.dx, tip.dy)
          ..quadraticBezierTo((mid - side).dx, (mid - side).dy, c.dx, c.dy),
        petal,
      );
    }
    _stud(canvas, c, rad * 0.18);
  }

  void _stud(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c.translate(r * 0.2, r * 0.3), r, Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: const [Color(0xFFFFF1C1), Color(0xFFD9A441), Color(0xFF7A5414)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_TeakDoorPainter oldDelegate) => oldDelegate.left != left;
}
