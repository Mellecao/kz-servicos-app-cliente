import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/cancel_trip_dialog.dart';

void main() {
  testWidgets('permite confirmar o cancelamento sem informar motivo', (
    tester,
  ) async {
    String? result;
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const CancelTripDialog(),
                );
                completed = true;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Motivo (opcional)'), findsOneWidget);
    await tester.tap(find.text('Cancelar corrida'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, '');
  });

  testWidgets('retorna o motivo sem espaços nas extremidades', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const CancelTripDialog(),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('cancel_reason_input')),
      '  Mudança de planos  ',
    );
    await tester.tap(find.text('Cancelar corrida'));
    await tester.pumpAndSettle();

    expect(result, 'Mudança de planos');
  });
}
