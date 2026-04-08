import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.lottieAsset,
    required this.isActive,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final String lottieAsset;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180,
              width: 180,
              child: Lottie.asset(
                lottieAsset,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 32),
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
      ),
    );
  }
}
