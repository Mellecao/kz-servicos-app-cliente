import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFFF1F0F0);
  static const Color highlight = Color(0xFFFEBF22);
  static const Color secondary = Color(0xFF2261FE);
  static const Color textPrimary = Color(0xFF5C5956);
  static const Color white = Colors.white;

  // Mesh gradient colors per slide
  static const List<Color> meshSlide1 = [
    Color(0xFFFEBF22),
    Color(0xFFFF9500),
    Color(0xFFFFD700),
    Color(0xFFFFA000),
  ];

  static const List<Color> meshSlide2 = [
    Color(0xFF2261FE),
    Color(0xFF1A47C2),
    Color(0xFF4A7DFF),
    Color(0xFF0D3B9E),
  ];

  static const List<Color> meshSlide3 = [
    Color(0xFFF1F0F0),
    Color(0xFFE0DFDF),
    Color(0xFFD5D4D4),
    Color(0xFFEAEAEA),
  ];
}
