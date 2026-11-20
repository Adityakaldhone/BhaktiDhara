import 'package:flutter/material.dart';

/// Extra colour tokens for the Naam Jaap feature, layered on `MandirTheme`.
class JaapColors {
  static const Color glowGold = Color(0xFFFFD27A);
  static const Color beadRudraksha = Color(0xFF6D3B1F);
  static const Color beadDone = Color(0xFFC0712F);
  static const Color thread = Color(0xFFC58B25);
  static const Color sumeru = Color(0xFF8B1D18);
  static const Color diyaFlame = Color(0xFFFF9F1C);
  static const Color sandalStart = Color(0xFFFFF3D6);
  static const Color sandalEnd = Color(0xFFF6DDAF);
  static const Color sandalDeep = Color(0xFFE8C98A);
  static const Color counterGold = Color(0xFFA86B12);
  static const Color mantraMaroon = Color(0xFF7B1E1E);

  /// Soft glass fill for chips and quiet chrome over the sandal background.
  static Color get surfaceGlass => Colors.white.withValues(alpha: 0.42);

  /// Secondary body ink that stays readable on sandal without competing.
  static const Color inkSoft = Color(0xFF5C4030);
}
