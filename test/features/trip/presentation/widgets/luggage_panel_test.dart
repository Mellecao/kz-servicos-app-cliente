import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/luggage_panel.dart';

void main() {
  Widget buildPanel(ValueChanged<List<LuggageItem>> onContinue) {
    return MaterialApp(
      home: LuggagePanel(onBack: () {}, onContinue: onContinue),
    );
  }

  testWidgets('allows continuing without luggage', (tester) async {
    List<LuggageItem>? result;
    await tester.pumpWidget(buildPanel((items) => result = items));

    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Tamanho'), findsOneWidget);
    expect(find.text('Peso (opcional)'), findsOneWidget);
    await tester.tap(find.text('Continuar'));

    expect(result, isEmpty);
  });

  testWidgets('supports the outbound-specific round-trip title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LuggagePanel(
          title: 'Bagagens da ida',
          onBack: () {},
          onContinue: (_) {},
        ),
      ),
    );

    expect(find.text('Bagagens da ida'), findsOneWidget);
  });

  testWidgets('saves a luggage summary and plus reveals another form', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel((_) {}));

    await tester.enterText(find.byKey(const Key('luggage_type')), 'Mala');
    await tester.enterText(find.byKey(const Key('luggage_size')), 'Grande');
    await tester.enterText(find.byKey(const Key('luggage_weight')), '23');
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(find.text('Mala • Grande • 23 kg'), findsOneWidget);
    expect(find.byKey(const Key('add_luggage')), findsOneWidget);
    expect(find.byKey(const Key('luggage_type')), findsNothing);

    await tester.tap(find.byKey(const Key('add_luggage')));
    await tester.pump();
    expect(find.byKey(const Key('luggage_type')), findsOneWidget);
  });
}
