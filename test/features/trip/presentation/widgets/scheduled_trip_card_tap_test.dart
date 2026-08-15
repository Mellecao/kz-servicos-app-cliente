import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/scheduled_trip_card.dart';

void main() {
  testWidgets('abre a ação pendente ao tocar no card inteiro', (tester) async {
    var tapped = false;
    final trip = ScheduledTrip(
      id: 'trip-1',
      status: 'awaiting_client_confirmation',
      scheduledDatetime: DateTime(2026, 8, 14, 16, 31),
      origin: 'Rua Indusquímica, 453 - Jardim Leonor',
      destination: 'Rodovia Hélio Smidt, s/nº - Aeroporto',
      originLat: -23.0,
      originLng: -46.0,
      destinationLat: -23.1,
      destinationLng: -46.1,
      passengerCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduledTripCard(trip: trip, onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(ScheduledTripCard));

    expect(tapped, isTrue);
  });
}
