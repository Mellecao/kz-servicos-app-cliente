import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('background should be #F1F0F0', () {
      expect(AppColors.background, const Color(0xFFF1F0F0));
    });

    test('highlight (laranja da marca Só Serviços) should be #FF9A52', () {
      expect(AppColors.highlight, const Color(0xFFFF9A52));
    });

    test('brand tokens follow the Só Serviços palette', () {
      expect(AppColors.primaryDark, const Color(0xFFE68B4A));
      expect(AppColors.primaryLight, const Color(0xFFFFB27A));
      expect(AppColors.pink, const Color(0xFFE54C65));
    });

    test('highlightSoft is a light orange tint (#FFE9D6) for soft surfaces', () {
      expect(AppColors.highlightSoft, const Color(0xFFFFE9D6));
    });

    test('onPrimary (texto sobre laranja) should be #1F2430, never white', () {
      expect(AppColors.onPrimary, const Color(0xFF1F2430));
      expect(AppColors.onPrimary, isNot(Colors.white));
    });

    test('brandGradient goes from pink to highlight', () {
      expect(AppColors.brandGradient.colors, [
        AppColors.pink,
        AppColors.highlight,
      ]);
    });

    test('secondary should be #2261FE', () {
      expect(AppColors.secondary, const Color(0xFF2261FE));
    });

    test('textPrimary should be #5C5956', () {
      expect(AppColors.textPrimary, const Color(0xFF5C5956));
    });

    test('white should be Colors.white', () {
      expect(AppColors.white, Colors.white);
    });

    test('meshSlide1 should have 4 colors', () {
      expect(AppColors.meshSlide1.length, 4);
    });

    test('meshSlide1 must not contain the old yellow family', () {
      const oldYellows = <Color>[
        Color(0xFFFEBF22),
        Color(0xFFE5AB1E),
        Color(0xFFFFD700),
        Color(0xFFFFA000),
      ];
      for (final color in AppColors.meshSlide1) {
        expect(oldYellows, isNot(contains(color)));
      }
    });

    test('meshSlide2 should have 4 colors', () {
      expect(AppColors.meshSlide2.length, 4);
    });

    test('meshSlide3 should have 4 colors', () {
      expect(AppColors.meshSlide3.length, 4);
    });
  });
}
