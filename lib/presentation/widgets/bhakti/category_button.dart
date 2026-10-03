import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/bhakti_deity.dart';

/// Glossy round button with a gold rim, used for a deity's content categories.
class BhaktiCategoryButton extends StatefulWidget {
  final BhaktiCategory category;
  final String localeCode;
  final double size;
  final VoidCallback onTap;

  const BhaktiCategoryButton({
    super.key,
    required this.category,
    required this.localeCode,
    required this.size,
    required this.onTap,
  });

  @override
  State<BhaktiCategoryButton> createState() => _BhaktiCategoryButtonState();
}

class _BhaktiCategoryButtonState extends State<BhaktiCategoryButton> {
  bool _pressed = false;

  static const _gradients = <BhaktiCategory, List<Color>>{
    BhaktiCategory.aarti: [Color(0xFFFF6A3D), Color(0xFFB3180C)],
    BhaktiCategory.chalisa: [Color(0xFFFF7F8E), Color(0xFFA8123A)],
    BhaktiCategory.mantra: [Color(0xFFFFB23D), Color(0xFFC25A06)],
    BhaktiCategory.bhajan: [Color(0xFFD85BD8), Color(0xFF6E117A)],
    BhaktiCategory.stotra: [Color(0xFFFF9F43), Color(0xFFB8460A)],
  };

  Widget _icon(double iconSize) {
    const shadows = [Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))];
    if (widget.category == BhaktiCategory.mantra) {
      return Text(
        'ॐ',
        style: GoogleFonts.notoSansDevanagari(
          fontSize: iconSize * 0.95,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: shadows,
        ),
      );
    }
    final icon = switch (widget.category) {
      BhaktiCategory.aarti => Icons.local_fire_department_rounded,
      BhaktiCategory.chalisa => Icons.auto_stories_rounded,
      BhaktiCategory.bhajan => Icons.music_note_rounded,
      _ => Icons.menu_book_rounded,
    };
    return Icon(icon, size: iconSize, color: Colors.white, shadows: shadows);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final colors = _gradients[widget.category]!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.06),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFE39A), Color(0xFFB07A1C), Color(0xFFF8D27A)],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFFFFBE50).withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.4),
                radius: 0.9,
                colors: colors,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _icon(size * 0.32),
                SizedBox(height: size * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.06),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.category.label(widget.localeCode),
                      maxLines: 1,
                      style: GoogleFonts.mukta(
                        fontSize: size * 0.2,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
