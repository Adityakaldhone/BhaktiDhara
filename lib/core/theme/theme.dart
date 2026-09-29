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

  /// Maps a deity name to its own portrait only — never another god's image.
  static String getDeityImageAsset(String deity) {
    switch (deity) {
      case 'Lord Ganesha':
        return 'assets/decorations/ganesh.png';
      case 'Lord Hanuman':
        return 'assets/decorations/hanuman.png';
      case 'Lord Shiva':
        return 'assets/decorations/mahadev.png';
      case 'Goddess Durga':
        return 'assets/decorations/durga.png';
      case 'Lord Krishna':
        return 'assets/decorations/krishna.png';
      case 'Lord Rama':
        return 'assets/decorations/rama.png';
      case 'Lord Vitthal':
        return 'assets/decorations/vitthal.png';
      case 'Lord Datta':
        return 'assets/decorations/datta.png';
      case 'Sai Baba':
        return 'assets/decorations/saibaba.png';
      case 'Gajanan Maharaj':
        return 'assets/decorations/gajanan_maharaj.png';
      case 'Lord Vishnu':
      case 'Lord Satyanarayan':
        return 'assets/decorations/vishnu.png';
      case 'Lord Khandoba':
        return 'assets/decorations/khandoba.png';
      case 'Lord Shani':
        return 'assets/decorations/shani.png';
      case 'Goddess Lakshmi':
        return 'assets/decorations/lakshmi.png';
      case 'Lord Venkatesh':
        return 'assets/decorations/venkatesh.png';
      case 'Goddess Tulsi':
        return 'assets/decorations/tulsi.png';
      case 'Goddess Santoshi Mata':
        return 'assets/decorations/santoshi_mata.png';
      case 'Sant':
        return 'assets/decorations/sant.png';
      default:
        return 'assets/decorations/om.png';
    }
  }
}
