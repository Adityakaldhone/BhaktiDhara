import 'package:flutter/material.dart';

import '../../../domain/entities/greeting_card.dart';

/// Colours for one card template. `title` and `muted` must stay
/// readable (WCAG 4.5:1) on both ends of the background gradient — cards are
/// mostly read by older eyes on small, dim screens.
class CardPalette {
  final Color top;
  final Color bottom;
  final Color frame;
  final Color title;
  final Color muted;
  final Color halo;

  const CardPalette({
    required this.top,
    required this.bottom,
    required this.frame,
    required this.title,
    required this.muted,
    required this.halo,
  });

  bool get isDark => bottom.computeLuminance() < 0.2;

  static CardPalette of(CardTemplate template) => switch (template) {
        CardTemplate.sandalGold => const CardPalette(
            top: Color(0xFFFFF6E5),
            bottom: Color(0xFFF1D6A0),
            frame: Color(0xFFB07A12),
            title: Color(0xFF7A1F0F),
            muted: Color(0xFF5E3F22),
            halo: Color(0xFFFFE7A3),
          ),
        CardTemplate.templeDusk => const CardPalette(
            top: Color(0xFF2A0F3D),
            bottom: Color(0xFF5B1A3A),
            frame: Color(0xFFE0B24A),
            title: Color(0xFFFFD77A),
            muted: Color(0xFFF1D9B5),
            halo: Color(0xFFFFB84D),
          ),
        CardTemplate.marigold => const CardPalette(
            top: Color(0xFFFFEBC0),
            bottom: Color(0xFFF6A94A),
            frame: Color(0xFF9E3D00),
            title: Color(0xFF7A0A00),
            muted: Color(0xFF5A2200),
            halo: Color(0xFFFFF1C2),
          ),
        CardTemplate.tulsiGreen => const CardPalette(
            top: Color(0xFFF1F8E8),
            bottom: Color(0xFFBBD9A2),
            frame: Color(0xFF8A6A12),
            title: Color(0xFF1F4D1A),
            muted: Color(0xFF34502A),
            halo: Color(0xFFFFF4C9),
          ),
        CardTemplate.royalBlue => const CardPalette(
            top: Color(0xFF0E1F4D),
            bottom: Color(0xFF1F3C88),
            frame: Color(0xFFE0B24A),
            title: Color(0xFFFFD77A),
            muted: Color(0xFFD6DCF5),
            halo: Color(0xFFFFD27A),
          ),
      };
}

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
