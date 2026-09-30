import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/greeting_card.dart';
import 'card_templates.dart';

part 'card_styles.dart';

/// Images drawn on a card, decoded up front so offscreen rendering never
/// waits on asset loading.
class CardImages {
  final ui.Image? deity;
  final bool deityIsCutout;
  final ui.Image? logo;
  final ui.Image? diya;
  final ui.Image? flower;
  final ui.Image? bell;
  final ui.Image? shankh;

  /// The sender's own photo, shown as a round badge beside their name.
  final ui.Image? photo;

  const CardImages({
    this.deity,
    this.deityIsCutout = false,
    this.logo,
    this.diya,
    this.flower,
    this.bell,
    this.shankh,
    this.photo,
  });
}

/// One status card at its logical size (9:16). The preview shows this widget
/// directly and the renderer rasterises the same widget at 3x, so what the
/// user sees is exactly what gets shared.
class GreetingCardCanvas extends StatelessWidget {
  const GreetingCardCanvas({super.key, required this.data, this.images = const CardImages()});

  static const Size logicalSize = Size(360, 640);

  final GreetingCardData data;
  final CardImages images;

  @override
  Widget build(BuildContext context) {
    final palette = CardPalette.of(data.template);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: logicalSize, textScaler: TextScaler.noScaling),
        child: SizedBox.fromSize(
          size: logicalSize,
          child: ClipRect(
            child: switch (data.style) {
              CardStyle.templeArch => _TempleArchCard(data: data, palette: palette, images: images),
              CardStyle.suryoday => _SuryodayCard(data: data, palette: palette, images: images),
              CardStyle.darshan => _DarshanCard(data: data, palette: palette, images: images),
              CardStyle.poojaThali => _PoojaThaliCard(data: data, palette: palette, images: images),
              CardStyle.rangoli => _RangoliCard(data: data, palette: palette, images: images),
              CardStyle.kamal => _KamalCard(data: data, images: images),
              CardStyle.rajwada => _RajwadaCard(data: data, images: images),
              CardStyle.om => _OmCard(data: data, images: images),
            },
          ),
        ),
      ),
    );
  }
}

class _CardFonts {
  static TextStyle display(double size, Color color) =>
      GoogleFonts.yatraOne(fontSize: size, color: color, height: 1.15);

  static TextStyle verse(double size, Color color) =>
      GoogleFonts.tiroDevanagariMarathi(fontSize: size, color: color, height: 1.45);

  static TextStyle body(double size, Color color, {FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.mukta(fontSize: size, color: color, fontWeight: weight, height: 1.25);
}

String _invocation(String lang) => lang == 'en' ? '॥ ॐ ॥' : '॥ श्री ॥';

String _senderLabel(String lang) => switch (lang) {
      'en' => 'With love,',
      _ => 'शुभेच्छुक',
    };

/// Deity in a gold temple arch with mandala corners.
class _TempleArchCard extends StatelessWidget {
  const _TempleArchCard({required this.data, required this.palette, required this.images});

  final GreetingCardData data;
  final CardPalette palette;
  final CardImages images;

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
        child: Padding(
          padding: _safeArea,
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      children: [
        Text(_invocation(data.lang), style: _CardFonts.body(15, palette.frame, weight: FontWeight.w700)),
        const Spacer(),
        _DeityArch(images: images, palette: palette, width: 252, height: 318),
        const Spacer(),
        FitText(data.jaykar, style: _CardFonts.verse(21, palette.isDark ? palette.title : palette.muted)),
        const SizedBox(height: 2),
        FitText(
          data.title,
          style: _CardFonts.display(46, palette.title).copyWith(
            shadows: [Shadow(color: palette.halo.withValues(alpha: 0.6), blurRadius: 14)],
          ),
        ),
        const SizedBox(height: 6),
        _Ornament(color: palette.frame),
        const Spacer(),
        _Footer(data: data, images: images, nameColor: palette.title, brandColor: palette.muted),
      ],
    );
  }
}

/// WhatsApp status overlays the top and bottom ~40px.
const _safeArea = EdgeInsets.fromLTRB(30, 42, 30, 38);

class _Footer extends StatelessWidget {
  const _Footer({
    required this.data,
    required this.images,
    required this.nameColor,
    required this.brandColor,
    this.shadows,
  });

  final GreetingCardData data;
  final CardImages images;
  final Color nameColor;
  final Color brandColor;
  final List<Shadow>? shadows;

  static const photoSize = 76.0;

  @override
  Widget build(BuildContext context) {
    final name = data.senderName;
    final photo = data.photoStamp == null ? null : images.photo;
    final hasName = name != null && name.isNotEmpty;
    final brand = data.brand.isEmpty
        ? const SizedBox.shrink()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (images.logo != null) ...[
                ClipOval(child: RawImage(image: images.logo, width: 16, height: 16, fit: BoxFit.cover)),
                const SizedBox(width: 5),
              ],
              Text(data.brand, style: _CardFonts.body(12, brandColor).copyWith(shadows: shadows)),
            ],
          );
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: photo == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (hasName)
          FitText(
            '${_senderLabel(data.lang)} $name',
            style: _CardFonts.body(18, nameColor, weight: FontWeight.w800).copyWith(shadows: shadows),
          ),
        const SizedBox(height: 2),
        brand,
      ],
    );
    final emojis = data.emojis;
    final sender = photo == null ? text : _withPhoto(photo, text);
    if (emojis == null || emojis.isEmpty) return sender;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sender,
        const SizedBox(height: 6),
        SizedBox(
          key: const Key('card-emoji-row'),
          height: emojiRowHeight,
          child: FitText(emojis, style: const TextStyle(fontSize: 26, height: 1.15)),
        ),
      ],
    );
  }

  static const emojiRowHeight = 32.0;

  Widget _withPhoto(ui.Image photo, Widget text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const Key('card-sender-photo'),
          width: photoSize,
          height: photoSize,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: nameColor,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6)],
          ),
          child: ClipOval(
            child: RawImage(image: photo, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: text),
      ],
    );
  }
}

/// Temple-arch window holding the deity. Cut-out images sit on a glowing halo;
/// full paintings fill the arch.
class _DeityArch extends StatelessWidget {
  const _DeityArch({
    required this.images,
    required this.palette,
    required this.width,
    required this.height,
  });

  final CardImages images;
  final CardPalette palette;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final image = images.deity;
    final inner = image == null
        ? Center(child: Text('ॐ', style: _CardFonts.display(width * 0.4, palette.frame)))
        : images.deityIsCutout
            ? Padding(
                padding: EdgeInsets.only(top: width * 0.08),
                child: RawImage(
                  image: image,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.medium,
                ),
              )
            : RawImage(
                image: image,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.4),
                filterQuality: FilterQuality.medium,
              );

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        foregroundPainter: _ArchBorderPainter(palette.frame),
        child: ClipPath(
          clipper: const _ArchClipper(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 0.85,
                colors: [palette.halo, palette.halo.withValues(alpha: 0.35), palette.top],
                stops: const [0, 0.6, 1],
              ),
            ),
            child: SizedBox.expand(child: inner),
          ),
        ),
      ),
    );
  }
}

Path _archPath(Size size) {
  final r = size.width / 2;
  return Path()
    ..moveTo(0, size.height)
    ..lineTo(0, r)
    ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
    ..lineTo(size.width, size.height)
    ..close();
}

class _ArchClipper extends CustomClipper<Path> {
  const _ArchClipper();

  @override
  Path getClip(Size size) => _archPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArchBorderPainter extends CustomPainter {
  const _ArchBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _archPath(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final outer = _archPath(Size(size.width + 10, size.height + 5)).shift(const Offset(-5, -5));
    canvas.drawPath(
      outer,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ArchBorderPainter oldDelegate) => oldDelegate.color != color;
}

/// Double gold border with mandala quarter-rosettes in each corner.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final thin = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.zero).deflate(10),
      line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.zero).deflate(14),
      thin,
    );

    final corners = [
      (Offset(10, 10), 0.0),
      (Offset(size.width - 10, 10), math.pi / 2),
      (Offset(size.width - 10, size.height - 10), math.pi),
      (Offset(10, size.height - 10), 3 * math.pi / 2),
    ];
    final petal = Paint()..color = color.withValues(alpha: 0.35);
    for (final (origin, rotation) in corners) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(rotation);
      for (final r in [18.0, 30.0, 42.0]) {
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), 0, math.pi / 2, false, thin);
      }
      for (var i = 0; i < 5; i++) {
        final angle = (i + 0.5) * (math.pi / 2) / 5;
        final center = Offset(math.cos(angle) * 36, math.sin(angle) * 36);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10, height: 4.5), petal);
        canvas.restore();
      }
      canvas.drawCircle(const Offset(8, 8), 2.2, petal);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => oldDelegate.color != color;
}

class _Ornament extends StatelessWidget {
  const _Ornament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(width: 54, height: 1.2, color: color.withValues(alpha: 0.7));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        bar(),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: 7, height: 7, color: color),
        ),
        const SizedBox(width: 6),
        bar(),
      ],
    );
  }
}

/// Text that shrinks until it fits its box, so long names and greetings
/// never overflow in any language.
class FitText extends StatelessWidget {
  const FitText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Scales at layout time with the real glyph metrics, so it stays correct
    // even when the card font finishes loading after the first frame.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, style: style, maxLines: 1, softWrap: false, textScaler: TextScaler.noScaling),
    );
  }
}
