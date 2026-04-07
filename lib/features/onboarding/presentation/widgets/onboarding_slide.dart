import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.textColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyBody,
              fontSize: 16,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
