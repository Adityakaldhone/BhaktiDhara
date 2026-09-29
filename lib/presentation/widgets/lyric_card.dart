import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Traditional devotional lyric stanza card styled like a sacred manuscript.
///
/// Features warm parchment background, antique gold border, subtle mandala
/// watermark on the right, and traditional Devanagari verse numbering.
class LyricCard extends StatelessWidget {
  final String devanagari;
  final String transliteration;
  final double fontScale;
  final String? stanzaNumber;
  final bool isActive;

  const LyricCard({
    super.key,
    required this.devanagari,
    required this.transliteration,
    required this.fontScale,
    this.stanzaNumber,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF0C8) : const Color(0xFFFDF3E1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isActive ? const Color(0xFFC47A1A) : const Color(0xFFD9A052),
          width: isActive ? 2.4 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0x44B54B18)
                : const Color(0x222E1104),
            blurRadius: isActive ? 18 : 14,
            spreadRadius: isActive ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Right-side decorative mandala watermark
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/decorations/card_right_design.png',
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Lyrics Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          devanagari,
                          style: GoogleFonts.notoSerifDevanagari(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9B0B08),
                            height: 1.45,
                          ),
                        ),
                        if (transliteration.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            transliteration,
                            style: GoogleFonts.inter(
                              fontSize: 13.5 * fontScale,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF71665B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Stanza Number Badge (|| १ ||)
                  if (stanzaNumber != null && stanzaNumber!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2B06A),
                          width: 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x122E1104),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '|| $stanzaNumber ||',
                        style: GoogleFonts.notoSerifDevanagari(
                          fontSize: 14 * fontScale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB54B18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
