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
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(find.text('Title'));
      expect(titleWidget.style?.color, Colors.red);

      final subtitleWidget = tester.widget<Text>(find.text('Subtitle'));
      expect(subtitleWidget.style?.color, Colors.red);
    });
  });
}
