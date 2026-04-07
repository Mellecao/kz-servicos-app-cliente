import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

abstract final class AppTheme {
  static const String _fontFamilyTitle = 'OutfitBlack';
  static const String _fontFamilyBody = 'QuasimodoSemiBold';

  static String get fontFamilyTitle => _fontFamilyTitle;
  static String get fontFamilyBody => _fontFamilyBody;

  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: _fontFamilyBody,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.highlight,
          surface: AppColors.background,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: _fontFamilyTitle,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
          bodyLarge: TextStyle(
            fontFamily: _fontFamilyBody,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      );
}
