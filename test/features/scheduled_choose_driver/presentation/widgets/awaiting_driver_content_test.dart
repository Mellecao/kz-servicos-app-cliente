import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/price_offer_details.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart';

void main() {
  const details = PriceOfferDetails(
    driverName: 'Motorista Teste',
    driverAvatarUrl: null,
    rating: 4.9,
    totalRatings: 128,
    completedTrips: 342,
    driverPhotoUrls: [],
    vehicle: PriceOfferVehicle(
      brand: 'Toyota',
      model: 'Corolla',
      year: 2024,
      color: 'Prata',
      licensePlate: 'ABC1D23',
      passengerCapacity: 4,
      photoUrls: [],
    ),
    pickupAddress: 'Rua das Flores, 120',
    stopAddresses: ['Av. Brasil, 450'],
    dropoffAddress: 'Aeroporto Internacional',
    scheduledDatetime: null,
    passengerCount: 2,
    childrenCount: 0,
    luggageCount: 1,
    observations: null,
  );

  testWidgets('mostra espera premium, radar e resumo da solicitação', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AwaitingDriverContent(
          details: details,
          cancelling: false,
          error: null,
          onContinue: () {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SOLICITAÇÃO ENVIADA'), findsOneWidget);
    expect(find.text('A aguardar Motorista Teste'), findsOneWidget);
    expect(find.byKey(const Key('advanced-search-radar')), findsOneWidget);
    expect(find.text('A aguardar resposta em tempo real'), findsOneWidget);
    expect(find.text('Toyota Corolla 2024'), findsOneWidget);
    expect(find.text('Rua das Flores, 120'), findsOneWidget);
    expect(find.text('Aeroporto Internacional'), findsOneWidget);
    expect(find.text('Continuar navegando'), findsOneWidget);
    expect(find.text('Cancelar solicitação'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
