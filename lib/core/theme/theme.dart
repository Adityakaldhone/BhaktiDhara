import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core theme definition for the Digital Mandir application.
/// 
/// Specifically designed for a 50+ demographic. It abandons the "hacker" dark/neon
/// aesthetic in favor of a clean, highly legible, high-contrast Light Theme
/// featuring traditional spiritual colors (Saffron, Maroon, Pure White).
class MandirTheme {
  // Brand Colors
  static const Color primarySaffron = Color(0xFFD84315); // Deep Bhagwa Saffron
  static const Color secondaryMaroon = Color(0xFF7B1E1E); // Rich Maroon
  static const Color goldenAccent = Color(0xFFC58B25); // Golden accents
  static const Color backgroundCream = Color(0xFFFCF6E8); // Warm cream/off-white (updated)
  static const Color surfaceWhite = Color(0xFFFBF7F1); // Soft beige/white for cards (updated)
  static const Color textDark = Color(0xFF3E2723); // Dark brown text
  static const Color textMuted = Color(0xFF756E66); // Muted brown (updated)

  // Chip specific colors
  static const Color chipBackground = Color(0xFFFAEDD2);
  static const Color chipBorder = Color(0xFFF2DDB7);
  static const Color chipText = Color(0xFF6B3425);

  // Aarti Card Colors
  static const Color cardBackground = Color(0xFFFFF8E8);
  static const Color cardBorder = Color(0xFFF3DFC0);
  static const Color imageSurface = Color(0xFFF9E8C8);
  static const Color cardTitle = Color(0xFFB52A20);
  static const Color cardSubtitle = Color(0xFF663B2B);
  static const Color tagBackground = Color(0xFFF8E7C5);
  static const Color tagBorder = Color(0xFFF1D4A7);
  static const Color tagText = Color(0xFF7A3B24);
  static const Color cardPrimaryButton = Color(0xFFE84A12);
  static const Color cardButtonText = Color(0xFFFFFFFF);
  static const Color arrowBackground = Color(0xFFFFFDF7);
  static const Color arrowIcon = Color(0xFF7B301E);
  static const Color cardMandala = Color(0xFFEACB91);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primarySaffron,
      scaffoldBackgroundColor: backgroundCream,
      
      appBarTheme:  AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primarySaffron, size: 28),
        titleTextStyle: GoogleFonts.mukta(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      textTheme: GoogleFonts.muktaTextTheme(const TextTheme(
        // Extremely legible default text styles
        bodyLarge: TextStyle(fontSize: 18, color: textDark, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 16, color: textDark),
        titleLarge: TextStyle(fontSize: 24, color: textDark, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 20, color: textDark, fontWeight: FontWeight.w600),
      )),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySaffron,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
