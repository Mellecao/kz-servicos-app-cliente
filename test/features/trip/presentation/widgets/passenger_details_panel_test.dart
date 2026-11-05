import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/passenger_form_data.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/passenger_details_panel.dart';

void main() {
  testWidgets('renders initial passenger details when provided', (
    tester,
  ) async {
    final initialData = PassengerFormData(
      adults: 3,
      scheduledDatetime: DateTime(2026, 6, 11, 14, 30),
      hasChildren: true,
      childrenDescription: '2 criancas pequenas',
      hasLuggage: true,
      luggageDescription: '3 malas',
      observations: 'Portao azul',
      paymentMethod: 'cash',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassengerDetailsPanel(
            initialData: initialData,
            onConfirm: (_) {},
            onBack: () {},
            onRestore: () {},
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('2 criancas pequenas'), findsOneWidget);
    expect(find.text('3 malas'), findsOneWidget);
    expect(find.text('Portao azul'), findsOneWidget);
  });

  testWidgets('hides return fields for one-way trips', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassengerDetailsPanel(
            isRoundTrip: false,
            onConfirm: (_) {},
            onBack: () {},
            onRestore: () {},
          ),
        ),
      ),
    );

    expect(find.text('Retorno'), findsNothing);
    expect(find.text('Data de retorno'), findsNothing);
    expect(find.text('Horário de retorno'), findsNothing);
  });

  testWidgets('shows leg label in the panel title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassengerDetailsPanel(
            legLabel: 'volta',
            onConfirm: (_) {},
            onBack: () {},
            onRestore: () {},
          ),
        ),
      ),
    );

    expect(find.text('Detalhes da volta'), findsOneWidget);
  });

  testWidgets('confirms scheduled datetime for return leg', (tester) async {
    PassengerFormData? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassengerDetailsPanel(
            isRoundTrip: true,
            legLabel: 'volta',
            initialData: PassengerFormData(
              adults: 1,
              scheduledDatetime: DateTime(2026, 6, 11, 17, 45),
            ),
            onConfirm: (data) => confirmed = data,
            onBack: () {},
            onRestore: () {},
          ),
        ),
      ),
    );

    expect(find.text('Detalhes da volta'), findsOneWidget);
    expect(find.text('17:45'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(confirmed?.isRoundTrip, isTrue);
    expect(confirmed?.scheduledDatetime, DateTime(2026, 6, 11, 17, 45));
    expect(confirmed?.returnDatetime, isNull);
  });
}
