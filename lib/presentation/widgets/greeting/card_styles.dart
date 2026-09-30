part of 'card_canvas.dart';

/// Deity as a round medallion. Cut-outs stand free (the style draws what is
/// behind them); full paintings are cropped into a gold-ringed circle.
class _DeityDisc extends StatelessWidget {
  const _DeityDisc({
    required this.images,
    required this.diameter,
    required this.ring,
    this.cutoutHeight,
  });

  final CardImages images;
  final double diameter;
  final Color ring;
  final double? cutoutHeight;

  @override
  Widget build(BuildContext context) {
    final image = images.deity;
    if (image != null && images.deityIsCutout) {
      return SizedBox(
        width: diameter * 1.1,
        height: cutoutHeight ?? diameter * 1.15,
        child: RawImage(
          image: image,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 3.5),
        boxShadow: [BoxShadow(color: ring.withValues(alpha: 0.35), blurRadius: 18)],
      ),
      child: ClipOval(
        child: image == null
            ? ColoredBox(
                color: ring.withValues(alpha: 0.15),
                child: Center(child: Text('ॐ', style: _CardFonts.display(diameter * 0.4, ring))),
              )
            : RawImage(
                image: image,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.35),
                filterQuality: FilterQuality.medium,
              ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.data,
    required this.jaykarColor,
    required this.titleColor,
    required this.glow,
    this.ornament,
  });

  final GreetingCardData data;
  final Color jaykarColor;
  final Color titleColor;
  final Color glow;
  final Color? ornament;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FitText(data.jaykar, style: _CardFonts.verse(21, jaykarColor).copyWith(shadows: [Shadow(color: glow, blurRadius: 10)])),
        const SizedBox(height: 2),
        FitText(
          data.title,
          style: _CardFonts.display(46, titleColor).copyWith(shadows: [Shadow(color: glow, blurRadius: 14)]),
        ),
        if (ornament != null) ...[
          const SizedBox(height: 6),
          _Ornament(color: ornament!),
        ],
      ],
    );
  }
}

// ── Suryoday: sunrise sky, rays and a marigold toran ─────────────────────────

class _SuryodayCard extends StatelessWidget {
  const _SuryodayCard({required this.data, required this.palette, required this.images});

  final GreetingCardData data;
  final CardPalette palette;
  final CardImages images;

  static const _maroon = Color(0xFF7A1F0F);
  static const _rust = Color(0xFF8A3B12);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF9A5A), Color(0xFFFFC27F), Color(0xFFFFE6BE), Color(0xFFFFF5E4)],
                stops: [0, 0.35, 0.62, 1],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _SunPainter(Offset(180, 250)))),
        const Positioned(top: 0, left: 0, right: 0, height: 70, child: CustomPaint(painter: _ToranPainter())),
        Padding(
          padding: _safeArea.copyWith(top: 70),
          child: Column(
            children: [
              const Spacer(),
              _DeityDisc(images: images, diameter: 232, ring: const Color(0xFFD4A017), cutoutHeight: 290),
              const Spacer(),
              _Greeting(
                data: data,
                jaykarColor: _rust,
                titleColor: _maroon,
                glow: const Color(0x99FFF3D6),
                ornament: const Color(0xFFB8561B),
              ),
              const Spacer(),
              _Footer(data: data, images: images, nameColor: _maroon, brandColor: _rust),
            ],
          ),
        ),
      ],
    );
  }
}

class _SunPainter extends CustomPainter {
  const _SunPainter(this.center);

  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 36; i++) {
      final angle = i * 2 * math.pi / 36;
      const spread = 0.04;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.cos(angle - spread) * 700, center.dy + math.sin(angle - spread) * 700)
        ..lineTo(center.dx + math.cos(angle + spread) * 700, center.dy + math.sin(angle + spread) * 700)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: i.isEven ? 0.16 : 0.07));
    }
    canvas.drawCircle(
      center,
      150,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFDF0), Color(0xE6FFE08A), Color(0x00FFC46B)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: 150)),
    );
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) => oldDelegate.center != center;
}

/// Marigold garland (toran) swagging across the top edge.
class _ToranPainter extends CustomPainter {
  const _ToranPainter();

  static const _orange = Color(0xFFF26B0F);
  static const _yellow = Color(0xFFFFB300);
  static const _leaf = Color(0xFF2E7D32);

  void _flower(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(c, r * 0.45, Paint()..color = Colors.black.withValues(alpha: 0.12));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const swags = 4;
    const top = 4.0;
    const sag = 26.0;
    for (var i = 0; i < swags; i++) {
      final x0 = size.width * i / swags;
      final x1 = size.width * (i + 1) / swags;
      for (var t = 0; t <= 14; t++) {
        final tt = t / 14;
        final x = x0 + (x1 - x0) * tt;
        final y = top + sag * 4 * tt * (1 - tt);
        _flower(canvas, Offset(x, y), 5.4, t.isEven ? _orange : _yellow);
      }
    }
    for (var i = 1; i < swags; i++) {
      final x = size.width * i / swags;
      for (var k = 0; k < 4; k++) {
        _flower(canvas, Offset(x, top + 10 + k * 10.5), 5, k.isEven ? _yellow : _orange);
      }
      canvas.save();
      canvas.translate(x, top + 58);
      canvas.drawOval(const Rect.fromLTWH(-4, -8, 8, 16), Paint()..color = _leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Darshan: the deity fills the card like a wallpaper ───────────────────────

class _DarshanCard extends StatelessWidget {
  const _DarshanCard({required this.data, required this.palette, required this.images});

  final GreetingCardData data;
  final CardPalette palette;
  final CardImages images;

  static const _gold = Color(0xFFFFD77A);
  static const _cream = Color(0xFFFFF8E7);
  static const _shadow = [Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 1))];

  @override
  Widget build(BuildContext context) {
    final image = images.deity;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 0.9,
                colors: [palette.halo, palette.top, palette.bottom],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
        if (image != null && !images.deityIsCutout)
          Positioned.fill(
            child: RawImage(image: image, fit: BoxFit.cover, alignment: const Alignment(0, -0.3), filterQuality: FilterQuality.medium),
          )
        else if (image != null)
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            height: 400,
            child: RawImage(image: image, fit: BoxFit.contain, alignment: Alignment.bottomCenter, filterQuality: FilterQuality.medium),
          ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x80000000), Color(0x00000000)],
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xB3000000), Color(0xF2000000)],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: _gold.withValues(alpha: 0.75), width: 1.2)),
          ),
        ),
        Padding(
          padding: _safeArea,
          child: Column(
            children: [
              Text(
                _invocation(data.lang),
                style: _CardFonts.body(15, _gold, weight: FontWeight.w700).copyWith(shadows: _shadow),
              ),
              const Spacer(),
              FitText(data.jaykar, style: _CardFonts.verse(21, _gold).copyWith(shadows: _shadow)),
              const SizedBox(height: 2),
              FitText(data.title, style: _CardFonts.display(46, _cream).copyWith(shadows: _shadow)),
              const SizedBox(height: 6),
              const _Ornament(color: _gold),
              const SizedBox(height: 16),
              _Footer(data: data, images: images, nameColor: _gold, brandColor: _cream, shadows: _shadow),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pooja Thali: bells, diya and flowers around the deity ────────────────────

class _PoojaThaliCard extends StatelessWidget {
  const _PoojaThaliCard({required this.data, required this.palette, required this.images});

  final GreetingCardData data;
  final CardPalette palette;
  final CardImages images;

  Widget _asset(ui.Image? image, double width, double height, {bool flip = false}) {
    if (image == null) return SizedBox(width: width, height: height);
    final raw = RawImage(image: image, width: width, height: height, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    return flip ? Transform.flip(flipX: true, child: raw) : raw;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.top, palette.bottom],
        ),
      ),
      child: CustomPaint(
        painter: _FramePainter(palette.frame),
        child: Stack(
          children: [
            Positioned(top: 0, left: 40, child: _asset(images.bell, 40, 96)),
            Positioned(top: 0, right: 40, child: _asset(images.bell, 40, 96)),
            Padding(
              padding: _safeArea,
              child: Column(
                children: [
                  Text(_invocation(data.lang), style: _CardFonts.body(15, palette.frame, weight: FontWeight.w700)),
                  const Spacer(),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [palette.halo, palette.halo.withValues(alpha: 0)]),
                        ),
                      ),
                      _DeityDisc(images: images, diameter: 212, ring: palette.frame, cutoutHeight: 248),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _asset(images.flower, 34, 34),
                        const SizedBox(width: 6),
                        _asset(images.shankh, 50, 46),
                        const SizedBox(width: 6),
                        _asset(images.diya, 78, 66),
                        const SizedBox(width: 6),
                        _asset(images.shankh, 50, 46, flip: true),
                        const SizedBox(width: 6),
                        _asset(images.flower, 34, 34),
                      ],
                    ),
                  ),
                  _Greeting(
                    data: data,
                    jaykarColor: palette.isDark ? palette.title : palette.muted,
                    titleColor: palette.title,
                    glow: palette.halo.withValues(alpha: 0.6),
                    ornament: palette.frame,
                  ),
                  const Spacer(),
                  _Footer(data: data, images: images, nameColor: palette.title, brandColor: palette.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rangoli: clean cream card with a drawn rangoli behind the deity ──────────

class _RangoliCard extends StatelessWidget {
  const _RangoliCard({required this.data, required this.palette, required this.images});

  final GreetingCardData data;
  final CardPalette palette;
  final CardImages images;

  static const _maroon = Color(0xFF8E1B1B);
  static const _saffron = Color(0xFF9A4508);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF5), Color(0xFFFFF1DC)],
        ),
      ),
      child: CustomPaint(
        painter: const _DotBorderPainter(),
        child: Padding(
          padding: _safeArea,
          child: Column(
            children: [
              Text(_invocation(data.lang), style: _CardFonts.body(15, _saffron, weight: FontWeight.w700)),
              const Spacer(),
              SizedBox(
                width: 300,
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: CustomPaint(painter: _RangoliPainter())),
                    _DeityDisc(images: images, diameter: 176, ring: const Color(0xFFC9971C), cutoutHeight: 230),
                  ],
                ),
              ),
              const Spacer(),
              _Greeting(
                data: data,
                jaykarColor: _saffron,
                titleColor: _maroon,
                glow: const Color(0x00000000),
                ornament: _maroon,
              ),
              const Spacer(),
              _Footer(data: data, images: images, nameColor: _maroon, brandColor: _saffron),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangoliPainter extends CustomPainter {
  const _RangoliPainter();

  void _petals(Canvas canvas, Offset c, int count, double radius, double length, double width, Color color,
      {double offset = 0}) {
    final paint = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(offset + i * 2 * math.pi / count);
      canvas.drawPath(
        Path()
          ..moveTo(radius, 0)
          ..quadraticBezierTo(radius + length / 2, -width, radius + length, 0)
          ..quadraticBezierTo(radius + length / 2, width, radius, 0),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    _petals(canvas, c, 8, 128, 18, 7, const Color(0xFF2E7D32), offset: math.pi / 8);
    _petals(canvas, c, 16, 96, 48, 15, const Color(0xFF9C2A1C));
    _petals(canvas, c, 16, 92, 36, 11, const Color(0xFFF28C28), offset: math.pi / 16);
    final gold = Paint()..color = const Color(0xFFC9971C);
    for (var i = 0; i < 32; i++) {
      final a = i * 2 * math.pi / 32;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 150, 2.6, gold);
    }
    canvas.drawCircle(c, 94, Paint()..color = const Color(0xFFFFF6E6));
    canvas.drawCircle(
      c,
      94,
      Paint()
        ..color = const Color(0xFFC9971C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotBorderPainter extends CustomPainter {
  const _DotBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(14);
    const colors = [Color(0xFF9C2A1C), Color(0xFFF28C28), Color(0xFFC9971C)];
    var i = 0;
    void dot(Offset p) => canvas.drawCircle(p, 2.2, Paint()..color = colors[i++ % colors.length]);
    for (var x = rect.left; x <= rect.right; x += 12) {
      dot(Offset(x, rect.top));
      dot(Offset(x, rect.bottom));
    }
    for (var y = rect.top + 12; y < rect.bottom; y += 12) {
      dot(Offset(rect.left, y));
      dot(Offset(rect.right, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Kamal: the deity rises from a pink lotus ─────────────────────────────────

class _KamalCard extends StatelessWidget {
  const _KamalCard({required this.data, required this.images});

  final GreetingCardData data;
  final CardImages images;

  static const _title = Color(0xFF7E1640);
  static const _muted = Color(0xFF8A2F52);
  static const _gold = Color(0xFFC9971C);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCE4EC), Color(0xFFFFF0E6), Color(0xFFFFF7EC)],
        ),
      ),
      child: CustomPaint(
        painter: const _FramePainter(_gold),
        child: Padding(
          padding: _safeArea,
          child: Column(
            children: [
              Text(_invocation(data.lang), style: _CardFonts.body(15, _muted, weight: FontWeight.w700)),
              const Spacer(),
              SizedBox(
                width: 300,
                height: 326,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 20,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color(0xFFFFF4D6), Color(0x00FFE3EC)]),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 110,
                      child: CustomPaint(painter: _LotusPainter()),
                    ),
                    Positioned(
                      // Round paintings sit down into the petals like cut-outs do.
                      top: images.deity != null && images.deityIsCutout ? 0 : 42,
                      child: _DeityDisc(images: images, diameter: 200, ring: _gold, cutoutHeight: 250),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _Greeting(
                data: data,
                jaykarColor: _muted,
                titleColor: _title,
                glow: const Color(0x80FFFFFF),
                ornament: _gold,
              ),
              const Spacer(),
              _Footer(data: data, images: images, nameColor: _title, brandColor: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotusPainter extends CustomPainter {
  const _LotusPainter();

  void _petal(Canvas canvas, Offset base, double angle, double length, double width, Color fill) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-width, -length * 0.5, 0, -length)
      ..quadraticBezierTo(width, -length * 0.5, 0, 0);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC9971C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height - 26);
    final leaf = Paint()..color = const Color(0xFF3E8E41);
    canvas.drawOval(Rect.fromCenter(center: base + const Offset(-96, 10), width: 110, height: 26), leaf);
    canvas.drawOval(Rect.fromCenter(center: base + const Offset(96, 10), width: 110, height: 26), leaf);
    for (final a in [-1.25, -0.8, 0.8, 1.25]) {
      _petal(canvas, base, a, 78, 26, const Color(0xFFE56B92));
    }
    for (final a in [-0.45, 0.0, 0.45]) {
      _petal(canvas, base, a, 92, 30, const Color(0xFFF59AB8));
    }
    for (final a in [-0.95, 0.95]) {
      _petal(canvas, base + const Offset(0, 4), a, 64, 24, const Color(0xFFF8B8CC));
    }
    final ripple = Paint()
      ..color = const Color(0x55C9971C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: base + Offset(0, 16 + i * 6.0), width: 220 + i * 40, height: 10 + i * 4),
        ripple,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Rajwada: royal maroon with gold, the same for every deity ────────────────

class _RajwadaCard extends StatelessWidget {
  const _RajwadaCard({required this.data, required this.images});

  final GreetingCardData data;
  final CardImages images;

  static const _palette = CardPalette(
    top: Color(0xFF5A1018),
    bottom: Color(0xFF2A0609),
    frame: Color(0xFFE2B657),
    title: Color(0xFFFFD77A),
    muted: Color(0xFFF3DDB0),
    halo: Color(0xFFB8452A),
  );

  @override
  Widget build(BuildContext context) {
    const p = _palette;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.1,
          colors: [Color(0xFF7A1A22), Color(0xFF4A0C12), Color(0xFF250508)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: CustomPaint(
        painter: const _FramePainter(Color(0xFFE2B657)),
        foregroundPainter: const _GoldCornerPainter(),
        child: Padding(
          padding: _safeArea,
          child: Column(
            children: [
              Text(_invocation(data.lang), style: _CardFonts.body(15, p.frame, weight: FontWeight.w700)),
              const Spacer(),
              _DeityArch(images: images, palette: p, width: 236, height: 300),
              const Spacer(),
              _Greeting(
                data: data,
                jaykarColor: p.muted,
                titleColor: p.title,
                glow: const Color(0x66E2B657),
                ornament: p.frame,
              ),
              const Spacer(),
              _Footer(data: data, images: images, nameColor: p.title, brandColor: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold paisley-like flourishes at the four inner corners.
class _GoldCornerPainter extends CustomPainter {
  const _GoldCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = const Color(0xCCE2B657)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final dot = Paint()..color = const Color(0xFFE2B657);
    final corners = [
      (const Offset(22, 22), 0.0),
      (Offset(size.width - 22, 22), math.pi / 2),
      (Offset(size.width - 22, size.height - 22), math.pi),
      (Offset(22, size.height - 22), 3 * math.pi / 2),
    ];
    for (final (origin, rotation) in corners) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(rotation);
      canvas.drawPath(
        Path()
          ..moveTo(0, 56)
          ..quadraticBezierTo(0, 0, 56, 0)
          ..moveTo(10, 40)
          ..quadraticBezierTo(10, 10, 40, 10),
        gold,
      );
      canvas.drawCircle(const Offset(18, 18), 3.2, dot);
      canvas.drawCircle(const Offset(62, 2), 2.2, dot);
      canvas.drawCircle(const Offset(2, 62), 2.2, dot);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Om: a large faint ॐ with soft sound-wave rings ───────────────────────────

class _OmCard extends StatelessWidget {
  const _OmCard({required this.data, required this.images});

  final GreetingCardData data;
  final CardImages images;

  static const _title = Color(0xFF7A1F0F);
  static const _muted = Color(0xFF6B3A12);
  static const _saffron = Color(0xFFE8892B);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF1DE), Color(0xFFFFE2BF), Color(0xFFFFF4E4)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _SoundWavePainter(Offset(180, 260)))),
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            height: 300,
            child: FittedBox(
              child: Text(
                'ॐ',
                style: _CardFonts.verse(300, _saffron.withValues(alpha: 0.14)).copyWith(height: 1),
              ),
            ),
          ),
          Padding(
            padding: _safeArea,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Spacer(),
                _DeityDisc(images: images, diameter: 212, ring: const Color(0xFFD4A017), cutoutHeight: 270),
                const Spacer(),
                _Greeting(
                  data: data,
                  jaykarColor: _muted,
                  titleColor: _title,
                  glow: const Color(0x99FFF3D6),
                  ornament: _saffron,
                ),
                const Spacer(),
                _Footer(data: data, images: images, nameColor: _title, brandColor: _muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundWavePainter extends CustomPainter {
  const _SoundWavePainter(this.center);

  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
        center,
        120.0 + i * 34,
        Paint()
          ..color = const Color(0xFFE8892B).withValues(alpha: 0.22 - i * 0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) => oldDelegate.center != center;
}
