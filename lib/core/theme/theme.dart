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
      case 'Radha':
      case 'Goddess Radha':
      case 'Radha Rani':
        return 'assets/decorations/radha.png';
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
      case 'Lord Narayana':
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
      case 'Goddess Renuka Mata':
      case 'Renuka Mata':
      case 'Renuka':
        return 'assets/decorations/renuka_mata.png';
      case 'Lord Siddhanath':
      case 'Siddhanath':
        return 'assets/decorations/siddhanath.png';
      case 'Lord Bhairavnath':
      case 'Bhairavnath':
      case 'Bhairav':
        return 'assets/decorations/bhairavnath.png';
      case 'Chandra Dev':
      case 'Chandra':
      case 'Lord Chandra':
        return 'assets/decorations/chandra.png';
      case 'Surya Dev':
      case 'Surya':
      case 'Lord Surya':
      case 'Surya Narayan':
        return 'assets/decorations/surya.png';
      case 'Goddess Narmada':
      case 'Narmada':
      case 'Narmada Mata':
      case 'Reva':
        return 'assets/decorations/narmada.png';
      case 'Gayatri':
      case 'Goddess Gayatri':
      case 'Gayatri Mata':
        return 'assets/decorations/gayatri.png';
      case 'Sant Balumama':
      case 'Balumama':
        return 'assets/decorations/balumama.png';
      case 'Gondavalekar Maharaj':
      case 'Brahmachaitanya Gondavalekar Maharaj':
        return 'assets/decorations/gondavalekar_maharaj.png';
      case 'Navnath':
      case 'Shri Navnath':
        return 'assets/decorations/navnath.png';
      case 'Swami Samarth':
      case 'Shri Swami Samarth':
        return 'assets/decorations/swami_samarth.png';
      case 'Sant':
        return 'assets/decorations/sant.png';
      default:
        // Case-insensitive & Devanagari fallback matching
        final clean = deity.trim().toLowerCase();
        if (clean.contains('bhairav')) return 'assets/decorations/bhairavnath.png';
        if (clean.contains('chandra') || clean.contains('shashi') || clean.contains('som') || clean.contains('चंद्र')) {
          return 'assets/decorations/chandra.png';
        }
        if (clean.contains('surya') || clean.contains('dinkar') || clean.contains('bhaskar') || clean.contains('aditya') || clean.contains('सूर्य')) {
          return 'assets/decorations/surya.png';
        }
        if (clean.contains('narmada') || clean.contains('reva') || clean.contains('नर्मदा')) {
          return 'assets/decorations/narmada.png';
        }
        if (clean.contains('gayatri') || clean.contains('गायत्री')) {
          return 'assets/decorations/gayatri.png';
        }
        if (clean.contains('balumama') || clean.contains('बाळू')) return 'assets/decorations/balumama.png';
        if (clean.contains('gondavalekar') || clean.contains('गोंदवलेकर')) {
          return 'assets/decorations/gondavalekar_maharaj.png';
        }
        if (clean.contains('navnath') || clean.contains('नवनाथ')) return 'assets/decorations/navnath.png';
        if (clean.contains('swami samarth') || clean.contains('स्वामी समर्थ')) {
          return 'assets/decorations/swami_samarth.png';
        }
        if (clean.contains('siddhanath') || clean.contains('सिद्धनाथ')) return 'assets/decorations/siddhanath.png';
        if (clean.contains('renuka') || clean.contains('रेणुका')) return 'assets/decorations/renuka_mata.png';
        if (clean.contains('radha') || clean.contains('राधा')) return 'assets/decorations/radha.png';
        if (clean.contains('ganesh') || clean.contains('ganapati') || clean.contains('vinayak') || clean.contains('गणेश') || clean.contains('गणपती')) {
          return 'assets/decorations/ganesh.png';
        }
        if (clean.contains('hanuman') || clean.contains('maruti') || clean.contains('bajrang') || clean.contains('हनुमान') || clean.contains('मारुती')) {
          return 'assets/decorations/hanuman.png';
        }
        if (clean.contains('shiv') || clean.contains('mahadev') || clean.contains('bhole') || clean.contains('shankar') || clean.contains('शिव') || clean.contains('महादेव')) {
          return 'assets/decorations/mahadev.png';
        }
        if (clean.contains('durga') || clean.contains('ambe') || clean.contains('bhavani') || clean.contains('दुर्गा') || clean.contains('अंबे')) {
          return 'assets/decorations/durga.png';
        }
        if (clean.contains('krishna') || clean.contains('gopal') || clean.contains('कृष्ण')) {
          return 'assets/decorations/krishna.png';
        }
        if (clean.contains('rama') || clean.contains('ram') || clean.contains('राम')) {
          return 'assets/decorations/rama.png';
        }
        if (clean.contains('vitthal') || clean.contains('vithoba') || clean.contains('pandurang') || clean.contains('विठ्ठल')) {
          return 'assets/decorations/vitthal.png';
        }
        if (clean.contains('datta') || clean.contains('dattatreya') || clean.contains('दत्त')) {
          return 'assets/decorations/datta.png';
        }
        if (clean.contains('sai') || clean.contains('साई')) return 'assets/decorations/saibaba.png';
        if (clean.contains('gajanan') || clean.contains('गजानन')) return 'assets/decorations/gajanan_maharaj.png';
        if (clean.contains('vishnu') || clean.contains('narayan') || clean.contains('satyanarayan') || clean.contains('nrusinha') || clean.contains('विष्णू')) {
          return 'assets/decorations/vishnu.png';
        }
        if (clean.contains('khandoba') || clean.contains('malhari') || clean.contains('खंडोबा')) {
          return 'assets/decorations/khandoba.png';
        }
        if (clean.contains('shani') || clean.contains('शनि')) return 'assets/decorations/shani.png';
        if (clean.contains('lakshmi') || clean.contains('laxmi') || clean.contains('लक्ष्मी')) {
          return 'assets/decorations/lakshmi.png';
        }
        if (clean.contains('venkatesh') || clean.contains('balaji') || clean.contains('व्यंकटेश')) {
          return 'assets/decorations/venkatesh.png';
        }
        if (clean.contains('tulsi') || clean.contains('तुळस')) return 'assets/decorations/tulsi.png';
        if (clean.contains('santoshi') || clean.contains('संतोषी')) return 'assets/decorations/santoshi_mata.png';
        if (clean.contains('sant') || clean.contains('संत')) return 'assets/decorations/sant.png';

        return 'assets/decorations/om.png';
    }
  }
}
