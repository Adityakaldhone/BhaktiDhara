import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme.dart';

class ChartToken {
  const ChartToken(this.text, {this.highlight = false});

  final String text;
  final bool highlight;
}

/// North Indian (diamond) kundali. House 1 is the top diamond and houses run
/// counter-clockwise; the number in each house is its rashi (1 = Mesha).
class NorthIndianChart extends StatelessWidget {
  const NorthIndianChart({
    super.key,
    required this.firstRashi,
    required this.houses,
    required this.formatNumber,
  }) : assert(houses.length == 12);

  /// Rashi index (0–11) occupying house 1.
  final int firstRashi;

  /// Tokens for houses 1–12.
  final List<List<ChartToken>> houses;
  final String Function(int) formatNumber;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _NorthIndianPainter(
          firstRashi: firstRashi,
          houses: houses,
          formatNumber: formatNumber,
          fontFamily: GoogleFonts.mukta().fontFamily,
          textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
        ),
      ),
    );
  }
}

class _NorthIndianPainter extends CustomPainter {
  _NorthIndianPainter({
    required this.firstRashi,
    required this.houses,
    required this.formatNumber,
    required this.fontFamily,
    required this.textScaler,
  });

  final int firstRashi;
  final List<List<ChartToken>> houses;
  final String Function(int) formatNumber;
  final String? fontFamily;
  final TextScaler textScaler;

  // Fractions of the chart side, houses 1–12.
  static const _planetCenters = [
    Offset(0.5, 0.22), Offset(0.25, 0.085), Offset(0.085, 0.25),
    Offset(0.25, 0.5), Offset(0.085, 0.75), Offset(0.25, 0.915),
    Offset(0.5, 0.78), Offset(0.75, 0.915), Offset(0.915, 0.75),
    Offset(0.75, 0.5), Offset(0.915, 0.25), Offset(0.75, 0.085),
  ];
  static const _rashiPositions = [
    Offset(0.5, 0.42), Offset(0.25, 0.195), Offset(0.195, 0.25),
    Offset(0.42, 0.5), Offset(0.195, 0.75), Offset(0.25, 0.805),
    Offset(0.5, 0.58), Offset(0.75, 0.805), Offset(0.805, 0.75),
    Offset(0.58, 0.5), Offset(0.805, 0.25), Offset(0.75, 0.195),
  ];

  /// Usable text width per house: kites are wide, the left/right triangles
  /// are narrow but tall.
  static double _maxWidth(int house) => switch (house) {
        0 || 3 || 6 || 9 => 0.27,
        2 || 4 || 8 || 10 => 0.15,
        _ => 0.3,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final stroke = Paint()
      ..color = MandirTheme.primarySaffron.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    final inset = stroke.strokeWidth / 2;
    final square = Rect.fromLTWH(inset, inset, s - 2 * inset, s - 2 * inset);
    canvas.drawRect(square, Paint()..color = const Color(0xFFFFFBF2));
    canvas.drawRect(square, stroke);
    canvas.drawLine(square.topLeft, square.bottomRight, stroke);
    canvas.drawLine(square.topRight, square.bottomLeft, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(s / 2, inset)
        ..lineTo(s - inset, s / 2)
        ..lineTo(s / 2, s - inset)
        ..lineTo(inset, s / 2)
        ..close(),
      stroke,
    );

    final numberStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: s * 0.034,
      fontWeight: FontWeight.w600,
      color: MandirTheme.textMuted,
      height: 1,
    );

    for (var h = 0; h < 12; h++) {
      final rashi = (firstRashi + h) % 12;
      final rp = _rashiPositions[h];
      _drawCentered(canvas, TextSpan(text: formatNumber(rashi + 1), style: numberStyle),
          p(rp.dx, rp.dy), s * 0.1);

      final tokens = houses[h];
      if (tokens.isEmpty) continue;
      final fontSize = s * (tokens.length > 4 ? 0.036 : 0.043);
      final base = TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: MandirTheme.textDark,
        height: 1.2,
      );
      final spans = <InlineSpan>[];
      for (var i = 0; i < tokens.length; i++) {
        if (i > 0) spans.add(TextSpan(text: ' ', style: base));
        spans.add(TextSpan(
          text: tokens[i].text,
          style: tokens[i].highlight
              ? base.copyWith(color: MandirTheme.primarySaffron)
              : base,
        ));
      }
      final c = _planetCenters[h];
      _drawCentered(canvas, TextSpan(children: spans), p(c.dx, c.dy), s * _maxWidth(h));
    }
  }

  void _drawCentered(Canvas canvas, InlineSpan span, Offset center, double maxWidth) {
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_NorthIndianPainter old) =>
      old.firstRashi != firstRashi ||
      old.houses != houses ||
      old.fontFamily != fontFamily ||
      old.textScaler != textScaler;
}
