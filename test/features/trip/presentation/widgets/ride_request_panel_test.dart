import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/ride_request_panel.dart';

void main() {
  Widget buildPanel({
    VoidCallback? onScheduleRequested,
    ValueChanged<bool>? onRoundTripChanged,
    RideRequestSuggestionsLoader? suggestionsLoader,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RideRequestPanel(
          onConfirm: (_) {},
          onScheduleRequested: onScheduleRequested ?? () {},
          onRoundTripChanged: onRoundTripChanged,
          suggestionsLoader: suggestionsLoader,
        ),
      ),
    );
  }

  testWidgets('immediate mode is local, one-way, and hides round-trip choice', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.text('Viagem agora'), findsOneWidget);
    expect(find.text('Agendar'), findsOneWidget);
    expect(find.byType(AnimatedAlign), findsOneWidget);
    expect(find.text('Ida e volta'), findsNothing);
    expect(find.text('Partida'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Agendar slides locally without opening the legacy popup', (
    tester,
  ) async {
    var popupRequested = false;
    await tester.pumpWidget(
      buildPanel(onScheduleRequested: () => popupRequested = true),
    );

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    expect(popupRequested, isFalse);
    expect(find.text('Somente ida'), findsOneWidget);
    expect(find.text('Ida e volta'), findsOneWidget);
  });

  testWidgets('returning to Viagem agora forces one-way', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(buildPanel(onRoundTripChanged: changes.add));

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ida e volta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viagem agora'));
    await tester.pumpAndSettle();

    expect(changes, [true, false]);
    expect(find.text('Ida e volta'), findsNothing);
  });

  testWidgets(
    'round trip adds two return address fields below outbound fields',
    (tester) async {
      await tester.pumpWidget(buildPanel());

      await tester.tap(find.text('Agendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ida e volta'));
      await tester.pumpAndSettle();

      expect(find.text('Partida'), findsOneWidget);
      expect(find.text('Destino'), findsOneWidget);
      expect(find.text('Embarque da volta'), findsOneWidget);
      expect(find.text('Destino da volta'), findsOneWidget);
      expect(find.byKey(const Key('outbound_address_card')), findsOneWidget);
      expect(find.byKey(const Key('return_address_card')), findsOneWidget);
      expect(find.byKey(const Key('address_cards_dots')), findsOneWidget);

      final outbound = tester.getRect(
        find.byKey(const Key('outbound_address_card')),
      );
      final dots = tester.getRect(find.byKey(const Key('address_cards_dots')));
      final returning = tester.getRect(
        find.byKey(const Key('return_address_card')),
      );
      expect(outbound.bottom, lessThanOrEqualTo(dots.top));
      expect(dots.bottom, lessThanOrEqualTo(returning.top));

      await tester.tap(find.text('Embarque da volta'));
      await tester.pumpAndSettle();
      expect(find.text('Moradas de ida'), findsOneWidget);
      expect(find.text('Moradas de volta'), findsOneWidget);
      expect(
        find.byKey(const Key('address_editor_outbound_pickup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('address_editor_return_pickup')),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping a read-only summary opens the full-screen editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    await tester.tap(find.text('Destino'));
    await tester.pumpAndSettle();

    expect(find.text('Inserir moradas'), findsOneWidget);
    expect(
      find.byKey(const Key('address_editor_outbound_dropoff')),
      findsOneWidget,
    );
  });

  testWidgets('round trip can advance with inverse return defaults', (
    tester,
  ) async {
    const destination = PlacePrediction(
      placeId: 'destination',
      description: 'Rua de Destino',
      matchedSubstrings: [],
    );
    await tester.pumpWidget(
      buildPanel(
        suggestionsLoader: ({required input, location}) async => const [
          destination,
        ],
      ),
    );

    await tester.tap(find.text('Destino'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address_editor_outbound_dropoff')),
      'Destino',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.text('Rua de Destino'));
    await tester.pump();
    await tester.tap(find.text('Guardar moradas'));
    await tester.pumpAndSettle();
    expect(find.text('Avançar'), findsOneWidget);

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ida e volta'));
    await tester.pumpAndSettle();

    expect(find.text('Avançar'), findsOneWidget);
  });
}
