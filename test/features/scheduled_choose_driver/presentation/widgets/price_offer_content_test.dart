import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/price_offer_details.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/widgets/price_offer_content.dart';

void main() {
  final details = PriceOfferDetails(
    driverName: 'João da Silva',
    driverAvatarUrl: null,
    rating: 4.9,
    totalRatings: 128,
    completedTrips: 342,
    driverPhotoUrls: const ['https://example.com/driver.jpg'],
    vehicle: const PriceOfferVehicle(
      brand: 'Chevrolet',
      model: 'Onix',
      year: 2024,
      color: 'Prata',
      licensePlate: 'ABC1D23',
      passengerCapacity: 4,
      photoUrls: ['https://example.com/car.jpg'],
    ),
    pickupAddress: 'Rua das Flores, 120 - Centro',
    stopAddresses: const ['Av. Brasil, 450'],
    dropoffAddress: 'Aeroporto Internacional',
    scheduledDatetime: DateTime(2026, 8, 15, 14, 30),
    passengerCount: 2,
    childrenCount: 1,
    luggageCount: 2,
    observations: 'Levar cadeirinha infantil',
  );

  testWidgets('exibe motorista, carro, rota e dados da viagem', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceOfferContent(
            details: details,
            offeredPrice: 84.50,
            busy: false,
            onAccept: () {},
            onReject: () {},
          ),
        ),
      ),
    );

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.textContaining('4,9'), findsOneWidget);
    expect(find.textContaining('342 viagens'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Chevrolet Onix'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Chevrolet Onix'), findsOneWidget);
    expect(find.text('ABC1D23'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rua das Flores, 120 - Centro'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rua das Flores, 120 - Centro'), findsOneWidget);
    expect(find.text('Av. Brasil, 450'), findsOneWidget);
    expect(find.text('Aeroporto Internacional'), findsOneWidget);
    expect(find.textContaining('2 passageiros'), findsOneWidget);
    expect(find.text('Confirmar por 84,50 Kz'), findsOneWidget);
    expect(find.text('Agora'), findsNothing);
    expect(find.byIcon(Icons.bolt_rounded), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('mantém ações visíveis em tela compacta e dispara callbacks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var accepted = false;
    var rejected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PriceOfferContent(
          details: details,
          offeredPrice: 84.50,
          busy: false,
          onAccept: () => accepted = true,
          onReject: () => rejected = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text('Confirmar por 84,50 Kz'));
    await tester.tap(find.text('Recusar'));

    expect(accepted, isTrue);
    expect(rejected, isTrue);

    final rejectWidth = tester
        .getSize(find.byKey(const Key('reject-offer')))
        .width;
    final acceptWidth = tester
        .getSize(find.byKey(const Key('accept-offer')))
        .width;
    expect(rejectWidth, acceptWidth);
  });
}
