import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/widgets/onboarding_dots.dart';

void main() {
  group('OnboardingDots', () {
    testWidgets('should render 3 dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingDots(
              count: 3,
              currentIndex: 0,
              activeColor: Colors.white,
            ),
          ),
        ),
      );

      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(3));
    });

    testWidgets('active dot should be larger', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingDots(
              count: 3,
              currentIndex: 1,
              activeColor: Colors.white,
            ),
          ),
        ),
      );

      final dots = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();

      expect(dots.length, 3);
    });
  });
}
