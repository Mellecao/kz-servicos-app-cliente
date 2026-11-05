import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/round_trip_address_sheet.dart';

const currentLocation = PlacePrediction(
  placeId: '_current_location_',
  description: 'A minha localização atual',
  matchedSubstrings: [],
);

const outboundDestination = PlacePrediction(
  placeId: 'outbound-destination',
  description: 'Aeroporto Internacional de Guarulhos',
  matchedSubstrings: [],
);

void main() {
  testWidgets('mostra quatro moradas e preenche a volta com a rota inversa', (
    tester,
  ) async {
    RoundTripAddressSelection? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundTripAddressSheet(
            initialOutboundPickup: currentLocation,
            suggestionsLoader: ({required input, location}) async =>
                input.contains('Aeroporto') ? [outboundDestination] : [],
            onDismissed: () {},
            onConfirmed: (selection) => confirmed = selection,
          ),
        ),
      ),
    );

    expect(find.text('Planeie a sua ida e volta'), findsOneWidget);
    expect(find.text('Partida (ida)'), findsOneWidget);
    expect(find.text('Destino (ida)'), findsOneWidget);
    expect(find.text('Partida (volta)'), findsOneWidget);
    expect(find.text('Destino (volta)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('round_trip_outbound_dropoff')),
      'Aeroporto',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    final airportSuggestion = find.text('Aeroporto Internacional de Guarulhos');
    await tester.ensureVisible(airportSuggestion);
    await tester.pumpAndSettle();
    await tester.tap(airportSuggestion);
    await tester.pump();

    expect(find.text('Aeroporto Internacional de Guarulhos'), findsNWidgets(2));
    expect(find.text('A minha localização atual'), findsNWidgets(2));

    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(confirmed, isNotNull);
    expect(confirmed!.outboundPickup.placeId, '_current_location_');
    expect(confirmed!.outboundDropoff.placeId, 'outbound-destination');
    expect(confirmed!.returnPickup.placeId, 'outbound-destination');
    expect(confirmed!.returnDropoff.placeId, '_current_location_');
  });
}
