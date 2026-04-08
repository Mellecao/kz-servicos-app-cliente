import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('background should be #F1F0F0', () {
      expect(AppColors.background, const Color(0xFFF1F0F0));
    });

    test('highlight should be #FEBF22', () {
      expect(AppColors.highlight, const Color(0xFFFEBF22));
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

    test('meshSlide2 should have 4 colors', () {
      expect(AppColors.meshSlide2.length, 4);
    });

    test('meshSlide3 should have 4 colors', () {
      expect(AppColors.meshSlide3.length, 4);
    });
  });
}
