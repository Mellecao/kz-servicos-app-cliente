import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/passenger_names_panel.dart';

void main() {
  Widget buildPanel(ValueChanged<List<PassengerName>> onContinue) {
    return MaterialApp(
      home: PassengerNamesPanel(
        currentClientName: 'Ana Cliente',
        currentClientAge: 30,
        onBack: () {},
        onContinue: onContinue,
      ),
    );
  }

  testWidgets('starts with the current client as a passenger', (tester) async {
    List<PassengerName>? result;
    await tester.pumpWidget(buildPanel((value) => result = value));

    expect(find.text('Ana Cliente'), findsOneWidget);
    await tester.tap(find.text('Continuar'));

    expect(result, hasLength(1));
    expect(result!.single.name, 'Ana Cliente');
    expect(result!.single.isChild, isFalse);
  });

  testWidgets('adds a passenger with integer age and warns for a child', (
    tester,
  ) async {
    List<PassengerName>? result;
    await tester.pumpWidget(buildPanel((value) => result = value));

    await tester.tap(find.text('Adicionar passageiro'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('passenger_name_0')), 'Bia');
    await tester.enterText(find.byKey(const Key('passenger_age_0')), '10');
    await tester.pump();

    expect(
      find.text('Crianças de até 10 anos precisam de cadeirinha.'),
      findsNothing,
    );
    await tester.tap(find.text('Continuar'));

    expect(result, hasLength(2));
    expect(result![1].name, 'Bia');
    expect(result![1].age, 10);
    expect(result![1].isChild, isTrue);
  });

  testWidgets('supports the outbound-specific round-trip title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PassengerNamesPanel(
          title: 'Passageiros da ida',
          currentClientName: 'Ana Cliente',
          currentClientAge: 30,
          onBack: () {},
          onContinue: (_) {},
        ),
      ),
    );

    expect(find.text('Passageiros da ida'), findsOneWidget);
  });

  testWidgets('asks for the client age when it is absent from the profile', (
    tester,
  ) async {
    List<PassengerName>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: PassengerNamesPanel(
          currentClientName: 'Ana Cliente',
          onBack: () {},
          onContinue: (value) => result = value,
        ),
      ),
    );

    expect(find.byKey(const Key('current_client_age')), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Continuar'),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const Key('current_client_age')), '10');
    await tester.pump();
    expect(
      find.text('Crianças de até 10 anos precisam de cadeirinha.'),
      findsNothing,
    );
    await tester.tap(find.text('Continuar'));

    expect(result!.single.age, 10);
    expect(result!.single.isChild, isTrue);
  });
}
