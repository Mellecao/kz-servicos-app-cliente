import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  Widget buildTestApp({String initialRoute = '/onboarding'}) {
    final router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Login Page'))),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('OnboardingPage', () {
    testWidgets('should display first slide title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Solicitar serviços KZ ficou ainda mais fácil'),
        findsOneWidget,
      );
    });

    testWidgets('should display "Pular" button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('should display "Próximo" with arrow', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Próximo'), findsOneWidget);
    });

    testWidgets('should display 3 dots', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('should contain MeshGradientBackground', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should navigate to next slide on "Próximo" tap',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.textContaining('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Segurança e Confiabilidade'),
        findsOneWidget,
      );
    });

    testWidgets('should show "Começar" on last slide', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to slide 2
      await tester.tap(find.textContaining('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Navigate to slide 3
      await tester.tap(find.textContaining('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Começar'), findsOneWidget);
      expect(find.text('Pular'), findsNothing);
    });

    testWidgets('should navigate to login on "Pular" tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Pular'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('should navigate to login on "Começar" tap', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to last slide
      await tester.tap(find.textContaining('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.textContaining('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.textContaining('Começar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
