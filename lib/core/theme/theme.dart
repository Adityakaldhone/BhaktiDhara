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
        return 'assets/bhakti/ganesh.webp';
      case 'Lord Hanuman':
        return 'assets/bhakti/hanuman.webp';
      case 'Lord Shiva':
        return 'assets/bhakti/shiva.webp';
      case 'Goddess Durga':
        return 'assets/bhakti/durga.webp';
      case 'Lord Krishna':
        return 'assets/bhakti/krishna.webp';
      case 'Radha':
      case 'Goddess Radha':
      case 'Radha Rani':
        return 'assets/bhakti/radha.webp';
      case 'Lord Rama':
        return 'assets/bhakti/rama.webp';
      case 'Lord Vitthal':
        return 'assets/bhakti/vitthal.webp';
      case 'Lord Datta':
        return 'assets/bhakti/dutt.webp';
      case 'Sai Baba':
        return 'assets/bhakti/saibaba.webp';
      case 'Gajanan Maharaj':
        return 'assets/bhakti/gajanan_maharaj.webp';
      case 'Lord Vishnu':
      case 'Lord Narayana':
      case 'Lord Satyanarayan':
        return 'assets/bhakti/vishnu.webp';
      case 'Lord Khandoba':
        return 'assets/bhakti/khandoba.webp';
      case 'Lord Shani':
        return 'assets/bhakti/shanidev.webp';
      case 'Goddess Lakshmi':
        return 'assets/bhakti/laxmi.webp';
      case 'Lord Venkatesh':
        return 'assets/bhakti/Venkateswara.webp';
      case 'Goddess Tulsi':
        return 'assets/bhakti/tulasi.webp';
      case 'Goddess Santoshi Mata':
        return 'assets/decorations/santoshi_mata.webp';
      case 'Goddess Renuka Mata':
      case 'Renuka Mata':
      case 'Renuka':
        return 'assets/bhakti/renuka.webp';
      case 'Lord Siddhanath':
      case 'Siddhanath':
        return 'assets/bhakti/siddhanth.webp';
      case 'Lord Bhairavnath':
      case 'Bhairavnath':
      case 'Bhairav':
        return 'assets/bhakti/bhairavnath.webp';
      case 'Chandra Dev':
      case 'Chandra':
      case 'Lord Chandra':
        return 'assets/bhakti/chandra.webp';
      case 'Surya Dev':
      case 'Surya':
      case 'Lord Surya':
      case 'Surya Narayan':
        return 'assets/bhakti/surya.webp';
      case 'Goddess Narmada':
      case 'Narmada':
      case 'Narmada Mata':
      case 'Reva':
        return 'assets/bhakti/narmada.webp';
      case 'Goddess Ganga':
      case 'Ganga':
      case 'Ganga Mata':
      case 'Maa Ganga':
        return 'assets/bhakti/ganga.webp';
      case 'Gayatri':
      case 'Goddess Gayatri':
      case 'Gayatri Mata':
        return 'assets/decorations/gayatri.webp';
      case 'Sant Balumama':
      case 'Balumama':
        return 'assets/bhakti/balumama.webp';
      case 'Gondavalekar Maharaj':
      case 'Brahmachaitanya Gondavalekar Maharaj':
        return 'assets/bhakti/gondavalekar_maharaj.webp';
      case 'Navnath':
      case 'Shri Navnath':
        return 'assets/bhakti/navnath.webp';
      case 'Swami Samarth':
      case 'Shri Swami Samarth':
        return 'assets/bhakti/swami_samartha.webp';
      case 'Sant':
        return 'assets/bhakti/dnyaneshwar.webp';
      case 'Mahakal':
      case 'Lord Mahakal':
      case 'Mahakaleshwar':
        return 'assets/bhakti/shiva.webp';
      case 'Khatu Shyam':
      case 'Lord Khatu Shyam':
      case 'Shyam Baba':
        return 'assets/bhakti/khatu_shyam.webp';
      case 'Somnath Mahadev':
        return 'assets/bhakti/somnath.webp';
      case 'Nageshwar Mahadev':
        return 'assets/bhakti/nageshwar.webp';
      case 'Bhadreshwar Mahadev':
        return 'assets/bhakti/bhadreshwar.webp';
      case 'Dwarkadhish':
        return 'assets/bhakti/dwarkadhish.webp';
      case 'Ranchhodrai':
        return 'assets/bhakti/ranchhodrai.webp';
      case 'Ranchhodji':
        return 'assets/bhakti/ranchhodji.webp';
      case 'Bhalka Tirth Krishna':
        return 'assets/bhakti/bhalka_tirth_krishna.webp';
      case 'Shamlaji':
        return 'assets/bhakti/shamlaji.webp';
      case 'Ambaji':
        return 'assets/bhakti/ambaji.webp';
      case 'Pavagadh Mahakali':
        return 'assets/bhakti/pavagadh_mahakali.webp';
      case 'Chamunda Mata':
        return 'assets/bhakti/chamunda.webp';
      case 'Bahuchar Mata':
        return 'assets/bhakti/bahuchar.webp';
      case 'Khodiyar Mata':
        return 'assets/bhakti/khodiyar.webp';
      case 'Ashapura Mata':
        return 'assets/bhakti/ashapura.webp';
      case 'Momai Mata':
        return 'assets/bhakti/momai.webp';
      case 'Meldi Mata':
        return 'assets/bhakti/meldi.webp';
      case 'Harsiddhi Mata':
        return 'assets/bhakti/harsiddhi.webp';
      case 'Umiya Mata':
        return 'assets/bhakti/umiya.webp';
      case 'Swaminarayan':
        return 'assets/bhakti/swaminarayan.webp';
      case 'Mahudi Ghantakarna Mahavir':
        return 'assets/bhakti/ghantakarna_mahavir.webp';
      case 'Salasar Balaji':
        return 'assets/bhakti/salasar_balaji.webp';
      case 'Mehandipur Balaji':
        return 'assets/bhakti/mehandipur_balaji.webp';
      case 'Shrinathji':
        return 'assets/bhakti/shrinathji.webp';
      case 'Govind Dev Ji':
        return 'assets/bhakti/govind_dev_ji.webp';
      case 'Charbhuja Nath':
        return 'assets/bhakti/charbhuja_nath.webp';
      case 'Eklingji':
        return 'assets/bhakti/eklingji.webp';
      case 'Brahma Ji':
        return 'assets/bhakti/brahma.webp';
      case 'Karni Mata':
        return 'assets/bhakti/karni_mata.webp';
      case 'Jeen Mata':
        return 'assets/bhakti/jeen_mata.webp';
      case 'Kaila Devi':
        return 'assets/bhakti/kaila_devi.webp';
      case 'Rani Sati Dadi':
        return 'assets/bhakti/rani_sati_dadi.webp';
      case 'Tripura Sundari':
        return 'assets/bhakti/tripura_sundari.webp';
      case 'Gogaji':
        return 'assets/bhakti/gogaji.webp';
      case 'Tejaji':
        return 'assets/bhakti/tejaji.webp';
      case 'Pabuji':
        return 'assets/bhakti/pabuji.webp';
      case 'Ramdevji':
        return 'assets/bhakti/ramdevji.webp';
      case 'Devnarayan Ji':
        return 'assets/bhakti/devnarayan.webp';
      case 'Mallinath Ji':
        return 'assets/bhakti/mallinath.webp';
      case 'Kedarnath':
        return 'assets/bhakti/kedarnath.webp';
      case 'Badrinath':
        return 'assets/bhakti/badrinath.webp';
      case 'Gangotri':
        return 'assets/bhakti/gangotri.webp';
      case 'Yamunotri':
        return 'assets/bhakti/yamunotri.webp';
      case 'Jageshwar Mahadev':
        return 'assets/bhakti/jageshwar.webp';
      case 'Neelkanth Mahadev':
        return 'assets/bhakti/neelkanth.webp';
      case 'Baleshwar Mahadev':
        return 'assets/bhakti/baleshwar.webp';
      case 'Kartik Swami':
        return 'assets/bhakti/kartik_swami.webp';
      case 'Narsingh Devta':
        return 'assets/bhakti/vishnu.webp';
      case 'Nanda Devi':
        return 'assets/bhakti/nanda_devi.webp';
      case 'Surkanda Devi':
        return 'assets/bhakti/surkanda_devi.webp';
      case 'Dhari Devi':
        return 'assets/bhakti/dhari_devi.webp';
      case 'Chandrabadni Devi':
        return 'assets/bhakti/durga.webp';
      case 'Golu Devta':
        return 'assets/bhakti/golu_devta.webp';
      case 'Mahasu Devta':
        return 'assets/bhakti/mahasu_devta.webp';
      default:
        // Case-insensitive & Devanagari fallback matching
        final clean = deity.trim().toLowerCase();
        if (clean.contains('mahakal') || clean.contains('महाकाल')) return 'assets/bhakti/shiva.webp';
        if (clean.contains('khatu') || clean.contains('खाटू')) return 'assets/bhakti/khatu_shyam.webp';
        if ((clean.contains('ganga') && !clean.contains('gangadhar')) || clean.contains('गंगा')) {
          return 'assets/bhakti/ganga.webp';
        }
        if (clean.contains('bhairav')) return 'assets/bhakti/bhairavnath.webp';
        if (clean.contains('chandra') || clean.contains('shashi') || clean.contains('som') || clean.contains('चंद्र')) {
          return 'assets/bhakti/chandra.webp';
        }
        if (clean.contains('surya') || clean.contains('dinkar') || clean.contains('bhaskar') || clean.contains('aditya') || clean.contains('सूर्य')) {
          return 'assets/bhakti/surya.webp';
        }
        if (clean.contains('narmada') || clean.contains('reva') || clean.contains('नर्मदा')) {
          return 'assets/bhakti/narmada.webp';
        }
        if (clean.contains('gayatri') || clean.contains('गायत्री')) {
          return 'assets/decorations/gayatri.webp';
        }
        if (clean.contains('balumama') || clean.contains('बाळू')) return 'assets/bhakti/balumama.webp';
        if (clean.contains('gondavalekar') || clean.contains('गोंदवलेकर')) {
          return 'assets/bhakti/gondavalekar_maharaj.webp';
        }
        if (clean.contains('navnath') || clean.contains('नवनाथ')) return 'assets/bhakti/navnath.webp';
        if (clean.contains('swami samarth') || clean.contains('स्वामी समर्थ')) {
          return 'assets/bhakti/swami_samartha.webp';
        }
        if (clean.contains('siddhanath') || clean.contains('सिद्धनाथ')) return 'assets/bhakti/siddhanth.webp';
        if (clean.contains('renuka') || clean.contains('रेणुका')) return 'assets/bhakti/renuka.webp';
        if (clean.contains('radha') || clean.contains('राधा')) return 'assets/bhakti/radha.webp';
        if (clean.contains('ganesh') || clean.contains('ganapati') || clean.contains('vinayak') || clean.contains('गणेश') || clean.contains('गणपती')) {
          return 'assets/bhakti/ganesh.webp';
        }
        if (clean.contains('hanuman') || clean.contains('maruti') || clean.contains('bajrang') || clean.contains('हनुमान') || clean.contains('मारुती')) {
          return 'assets/bhakti/hanuman.webp';
        }
        if (clean.contains('shiv') || clean.contains('mahadev') || clean.contains('bhole') || clean.contains('shankar') || clean.contains('शिव') || clean.contains('महादेव')) {
          return 'assets/bhakti/shiva.webp';
        }
        if (clean.contains('durga') || clean.contains('ambe') || clean.contains('bhavani') || clean.contains('दुर्गा') || clean.contains('अंबे')) {
          return 'assets/bhakti/durga.webp';
        }
        if (clean.contains('krishna') || clean.contains('gopal') || clean.contains('कृष्ण')) {
          return 'assets/bhakti/krishna.webp';
        }
        if (clean.contains('rama') || clean.contains('ram') || clean.contains('राम')) {
          return 'assets/bhakti/rama.webp';
        }
        if (clean.contains('vitthal') || clean.contains('vithoba') || clean.contains('pandurang') || clean.contains('विठ्ठल')) {
          return 'assets/bhakti/vitthal.webp';
        }
        if (clean.contains('datta') || clean.contains('dattatreya') || clean.contains('दत्त')) {
          return 'assets/bhakti/dutt.webp';
        }
        if (clean.contains('sai') || clean.contains('साई')) return 'assets/bhakti/saibaba.webp';
        if (clean.contains('gajanan') || clean.contains('गजानन')) return 'assets/bhakti/gajanan_maharaj.webp';
        if (clean.contains('vishnu') || clean.contains('narayan') || clean.contains('satyanarayan') || clean.contains('nrusinha') || clean.contains('विष्णू')) {
          return 'assets/bhakti/vishnu.webp';
        }
        if (clean.contains('khandoba') || clean.contains('malhari') || clean.contains('खंडोबा')) {
          return 'assets/bhakti/khandoba.webp';
        }
        if (clean.contains('shani') || clean.contains('शनि')) return 'assets/bhakti/shanidev.webp';
        if (clean.contains('lakshmi') || clean.contains('laxmi') || clean.contains('लक्ष्मी')) {
          return 'assets/bhakti/laxmi.webp';
        }
        if (clean.contains('venkatesh') || clean.contains('balaji') || clean.contains('व्यंकटेश')) {
          return 'assets/bhakti/Venkateswara.webp';
        }
        if (clean.contains('tulsi') || clean.contains('तुळस')) return 'assets/bhakti/tulasi.webp';
        if (clean.contains('santoshi') || clean.contains('संतोषी')) return 'assets/decorations/santoshi_mata.webp';
        if (clean.contains('sant') || clean.contains('संत')) return 'assets/bhakti/dnyaneshwar.webp';

        return 'assets/decorations/om.png';
    }
  }
}
