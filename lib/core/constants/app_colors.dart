import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFFF1F0F0);

  // Marca "Só Serviços": laranja primário + rosa. Fonte única das cores da marca.
  static const Color highlight = Color(0xFFFF9A52);
  static const Color primaryDark = Color(0xFFE68B4A);
  static const Color primaryLight = Color(0xFFFFB27A);
  static const Color pink = Color(0xFFE54C65);

  /// Tom claro do laranja para superfícies suaves (banners, avatares).
  static const Color highlightSoft = Color(0xFFFFE9D6);

  /// Texto/ícones sobre a cor primária. Nunca usar branco sobre laranja.
  static const Color onPrimary = Color(0xFF1F2430);

  /// Fundo escuro da marca (ícone, splash).
  static const Color brandDark = Color(0xFF16161D);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [pink, highlight],
  );

  static const Color secondary = Color(0xFF2261FE);
  static const Color textPrimary = Color(0xFF5C5956);
  static const Color textSecondary = Color(0xFF8E8B88);
  static const Color white = Colors.white;

  // Tema escuro dos painéis do fluxo "Viagem agora" (spec 2026-08-16)
  static const Color sheetBackground = Color(0xFF141414);
  static const Color sheetSurface = Color(0xFF262626);
  static const Color sheetTextPrimary = Colors.white;
  static const Color sheetTextSecondary = Color(0xFF8A8A8A);

  // Mesh gradient colors per slide
  static const List<Color> meshSlide1 = [
    highlight,
    primaryDark,
    primaryLight,
    pink,
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
