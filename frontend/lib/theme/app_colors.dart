import 'package:flutter/material.dart';

class AppColors {
  static const MaterialColor emerald = MaterialColor(
    0xFF10B981, // Rich emerald green primary
    <int, Color>{
      50: Color(0xFFECFDF5),
      100: Color(0xFFD1FAE5),
      200: Color(0xFFA7F3D0),
      300: Color(0xFF6EE7B7),
      400: Color(0xFF34D399),
      500: Color(0xFF10B981),
      600: Color(0xFF059669),
      700: Color(0xFF047857),
      800: Color(0xFF065F46),
      900: Color(0xFF064E3B),
    },
  );

  static const MaterialAccentColor emeraldAccent = MaterialAccentColor(
    0xFF34D399,
    <int, Color>{
      100: Color(0xFFA7F3D0),
      200: Color(0xFF6EE7B7),
      400: Color(0xFF34D399),
      700: Color(0xFF059669),
    },
  );

  static const Color darkBackground = Color(0xFF0F172A); // Midnight slate bg
  static const Color cardBg = Color(0xFF1E293B); // Dark slate card bg
}
