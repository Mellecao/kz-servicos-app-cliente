import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart';

void main() {
  group('StepScaffold', () {
    testWidgets('renders as a bottom sheet instead of filling the screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: StepScaffold(
                title: 'Passageiros',
                onBack: () {},
                confirmLabel: 'Continuar',
                onConfirm: () {},
                child: const Text('Conteúdo'),
              ),
            ),
          ),
        ),
      );

      final rect = tester.getRect(find.byKey(const Key('booking_step_sheet')));
      expect(rect.bottom, 844);
      expect(rect.top, greaterThan(200));
      expect(rect.height, lessThan(644));
    });

    testWidgets('renders title and child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () {},
            confirmLabel: 'Continuar',
            onConfirm: () {},
            child: const Text('Conteúdo do passo'),
          ),
        ),
      );

      expect(find.text('Forma de pagamento'), findsOneWidget);
      expect(find.text('Conteúdo do passo'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('tapping the back arrow calls onBack', (tester) async {
      var backTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () => backTapped = true,
            confirmLabel: 'Continuar',
            onConfirm: () {},
            child: const SizedBox(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('tapping the confirm button calls onConfirm', (tester) async {
      var confirmTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () {},
            confirmLabel: 'Continuar',
            onConfirm: () => confirmTapped = true,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(confirmTapped, isTrue);
    });

    testWidgets('confirm button is disabled when onConfirm is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () {},
            confirmLabel: 'Continuar',
            onConfirm: null,
            child: const SizedBox(),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
