import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/return_details_panel.dart';

void main() {
  testWidgets('matches the compact return-details reference at 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ReturnDetailsPanel(
              currentClientName: 'Cliente Teste',
              initialPassengers: const [
                TripPassengerData(name: 'Cliente Teste', age: 30),
              ],
              initialLuggage: const [
                TripLuggageData(
                  type: 'Mala de mão',
                  size: 'large',
                  weightKg: 2.5,
                ),
              ],
              onBack: () {},
              onConfirm: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Detalhes da volta'), findsOneWidget);
    expect(find.text('Selecionar Data...'), findsOneWidget);
    expect(find.text('Selecionar Hora...'), findsOneWidget);
    expect(find.text('Cliente Teste (Eu)'), findsOneWidget);
    expect(find.text('Nome do Passageiro...'), findsOneWidget);
    expect(find.text('Idade...'), findsOneWidget);
    expect(find.text('Bagagem (opcional)'), findsOneWidget);
    expect(find.text('Mala de mão'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('2,5KG'), findsOneWidget);
    expect(find.text('Tipo da bagagem'), findsOneWidget);
    expect(find.text('Tamanho'), findsOneWidget);
    expect(find.text('Peso (opcional)'), findsOneWidget);
    expect(find.text('Avançar'), findsOneWidget);

    expect(find.text('Data e Horário'), findsNothing);
    expect(find.text('Possui crianças?'), findsNothing);
    expect(find.text('Possui malas?'), findsNothing);
    expect(find.text('Observação'), findsNothing);

    final panel = tester.getRect(find.byKey(const Key('return_details_panel')));
    expect(panel.height, closeTo(844 * .72, 1));
    expect(panel.top, closeTo(844 * .28, 1));

    final dateCard = tester.getRect(
      find.byKey(const Key('return_date_time_card')),
    );
    final passengerCard = tester.getRect(
      find.byKey(const Key('return_passengers_card')),
    );
    final luggageCard = tester.getRect(
      find.byKey(const Key('return_luggage_card')),
    );
    expect(dateCard.bottom, lessThan(passengerCard.top));
    expect(passengerCard.bottom, lessThan(luggageCard.top));
  });
}
