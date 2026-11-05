import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/payment_method_panel.dart';

void main() {
  Widget host(ValueChanged<String> onConfirm, {VoidCallback? onBack}) =>
      MaterialApp(
        home: PaymentMethodPanel(onConfirm: onConfirm, onBack: onBack ?? () {}),
      );

  group('PaymentMethodPanel', () {
    testWidgets('mostra Numerário, Multicaixa e cartão de crédito (sem PIX)', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) {}));

      expect(find.text('Pagamento'), findsOneWidget);
      expect(find.text('Numerário'), findsOneWidget);
      expect(find.text('Multicaixa / cartão de débito'), findsOneWidget);
      expect(find.text('Cartão de crédito'), findsOneWidget);
      expect(find.text('PIX'), findsNothing);
      expect(find.text('Pedir viagem'), findsOneWidget);
    });

    testWidgets('confirma com numerário por omissão', (tester) async {
      String? confirmed;
      await tester.pumpWidget(host((m) => confirmed = m));

      await tester.tap(find.text('Pedir viagem'));
      await tester.pump();

      expect(confirmed, 'cash');
    });

    testWidgets('confirma com débito ao escolher Multicaixa', (tester) async {
      String? confirmed;
      await tester.pumpWidget(host((m) => confirmed = m));

      await tester.tap(find.text('Multicaixa / cartão de débito'));
      await tester.pump();
      await tester.tap(find.text('Pedir viagem'));
      await tester.pump();

      expect(confirmed, 'debit');
    });

    testWidgets('confirma com crédito ao escolher cartão de crédito', (
      tester,
    ) async {
      String? confirmed;
      await tester.pumpWidget(host((m) => confirmed = m));

      await tester.tap(find.text('Cartão de crédito'));
      await tester.pump();
      await tester.tap(find.text('Pedir viagem'));
      await tester.pump();

      expect(confirmed, 'credit');
    });

    testWidgets('tapping back arrow calls onBack', (tester) async {
      var backTapped = false;
      await tester.pumpWidget(host((_) {}, onBack: () => backTapped = true));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backTapped, isTrue);
    });
  });
}
