import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('should display "Login" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should display "Cadastre-se" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Cadastre-se'), findsOneWidget);
    });

    testWidgets('should have two main action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should contain background image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should use Stack layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('login button should open bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Acesse sua conta'), findsOneWidget);
    });

    testWidgets('register button should open bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      expect(find.text('Crie sua conta'), findsOneWidget);
    });

    testWidgets('login bottom sheet should have email and password fields',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });
  });
}
