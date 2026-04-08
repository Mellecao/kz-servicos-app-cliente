import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_slide.dart';

void main() {
  group('OnboardingSlide', () {
    testWidgets('should display title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              textColor: Colors.white,
              lottieAsset: 'assets/animations/smartphone_tap.json',
              isActive: true,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('should use correct text color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Title',
              subtitle: 'Subtitle',
              textColor: Colors.red,
              lottieAsset: 'assets/animations/smartphone_tap.json',
              isActive: true,
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(find.text('Title'));
      expect(titleWidget.style?.color, Colors.red);
    });

    testWidgets('should have AnimatedOpacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Title',
              subtitle: 'Subtitle',
              textColor: Colors.white,
              lottieAsset: 'assets/animations/smartphone_tap.json',
              isActive: true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });

    testWidgets('should be transparent when not active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingSlide(
              title: 'Title',
              subtitle: 'Subtitle',
              textColor: Colors.white,
              lottieAsset: 'assets/animations/smartphone_tap.json',
              isActive: false,
            ),
          ),
        ),
      );

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    });
  });
}
