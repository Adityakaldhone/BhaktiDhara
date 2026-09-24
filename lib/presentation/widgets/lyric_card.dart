import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Static lyric stanza card tailored for high readability.
class LyricCard extends StatelessWidget {
  final String devanagari;
  final String transliteration;
  final double fontScale;

  const LyricCard({
    super.key,
    required this.devanagari,
    required this.transliteration,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: MandirTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            devanagari,
            style: TextStyle(
              fontSize: 24 * fontScale, // Large primary reading text
              fontWeight: FontWeight.w700,
              color: MandirTheme.textDark,
              height: 1.8, // Extra breathing room for Devanagari matras
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MandirTheme.backgroundCream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transliteration,
              style: TextStyle(
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.w500,
                color: MandirTheme.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
