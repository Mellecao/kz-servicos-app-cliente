import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/liquid_glass_card.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';

void main() {
  group('LoginPage', () {
    testWidgets('should display email field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
    });

    testWidgets('should display password field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
    });

    testWidgets('should display "Entrar" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('should display "Criar conta" link', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('password field should obscure text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Senha'),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('should contain LiquidGlassCard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LiquidGlassCard), findsOneWidget);
    });

    testWidgets('should contain BackdropFilter for glass effect',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });
}
