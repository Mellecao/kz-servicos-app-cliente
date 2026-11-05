import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/address_editor_screen.dart';

const pickup = PlacePrediction(
  placeId: 'pickup',
  description: 'Rua de Partida',
  matchedSubstrings: [],
);
const destination = PlacePrediction(
  placeId: 'destination',
  description: 'Rua de Destino',
  matchedSubstrings: [],
);

void main() {
  testWidgets('autocomplete is available in the full-screen one-way editor', (
    tester,
  ) async {
    AddressEditorSelection? result;
    await tester.pumpWidget(
      MaterialApp(
        home: AddressEditorScreen(
          initialPickup: pickup,
          isRoundTrip: false,
          onSaved: (value) => result = value,
          suggestionsLoader: ({required input, location}) async => const [
            destination,
          ],
        ),
      ),
    );

    expect(find.text('Inserir moradas'), findsOneWidget);
    expect(find.text('Inserir local no mapa manualmente'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('address_editor_outbound_dropoff')),
      'Destino',
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Bairro, cidade, complemento e cep'), findsNothing);
    await tester.ensureVisible(find.text('Rua de Destino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rua de Destino'));
    await tester.pump();
    await tester.tap(find.text('Guardar moradas'));

    expect(result, isNotNull);
    expect(result!.outboundPickup, pickup);
    expect(result!.outboundDropoff, destination);
  });

  testWidgets(
    'round trip shows outbound and return fields on the same screen',
    (tester) async {
      AddressEditorSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: AddressEditorScreen(
            initialPickup: pickup,
            isRoundTrip: true,
            onSaved: (value) => result = value,
            suggestionsLoader: ({required input, location}) async => const [
              destination,
            ],
          ),
        ),
      );

      expect(find.text('Inserir moradas'), findsOneWidget);
      expect(find.text('Moradas de ida'), findsOneWidget);
      expect(find.text('Moradas de volta'), findsOneWidget);
      expect(
        find.byKey(const Key('address_editor_return_pickup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('address_editor_return_dropoff')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('address_editor_outbound_dropoff')),
        'Destino',
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.ensureVisible(find.text('Rua de Destino'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rua de Destino'));
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('address_editor_return_pickup')),
            )
            .controller!
            .text,
        'Rua de Destino',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('address_editor_return_dropoff')),
            )
            .controller!
            .text,
        'Rua de Partida',
      );

      await tester.tap(find.text('Guardar moradas'));
      expect(result, isNotNull);
      expect(result!.returnPickup, destination);
      expect(result!.returnDropoff, pickup);
    },
  );

  testWidgets('allows at most three outbound stops', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddressEditorScreen(
          initialPickup: pickup,
          isRoundTrip: false,
          onSaved: (_) {},
          suggestionsLoader: ({required input, location}) async => const [],
        ),
      ),
    );

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const Key('add_outbound_stop')));
      await tester.pump();
    }

    expect(find.text('Parada 1'), findsOneWidget);
    expect(find.text('Parada 2'), findsOneWidget);
    expect(find.text('Parada 3'), findsOneWidget);
    expect(find.text('Parada 4'), findsNothing);
  });

  testWidgets('address fields and add-stop button do not overlap at 390px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AddressEditorScreen(
          initialPickup: pickup,
          isRoundTrip: false,
          onSaved: (_) {},
          suggestionsLoader: ({required input, location}) async => const [],
        ),
      ),
    );

    final destinationRect = tester.getRect(
      find.byKey(const Key('address_field_outbound_dropoff')),
    );
    final addButtonRect = tester.getRect(
      find.byKey(const Key('add_outbound_stop')),
    );
    final pickupRect = tester.getRect(
      find.byKey(const Key('address_field_outbound_pickup')),
    );
    final pickupLabelRect = tester.getRect(find.text('Partida'));
    final destinationLabelRect = tester.getRect(find.text('Destino'));

    expect(destinationRect.height, greaterThanOrEqualTo(56));
    expect(destinationRect.right + 8, lessThanOrEqualTo(addButtonRect.left));
    expect(pickupRect.contains(pickupLabelRect.center), isTrue);
    expect(destinationRect.contains(destinationLabelRect.center), isTrue);
    expect(pickupLabelRect.top, greaterThanOrEqualTo(pickupRect.top + 6));
    expect(
      destinationLabelRect.top,
      greaterThanOrEqualTo(destinationRect.top + 6),
    );
    final pickupInputRect = tester.getRect(
      find.byKey(const Key('address_editor_outbound_pickup')),
    );
    final destinationInputRect = tester.getRect(
      find.byKey(const Key('address_editor_outbound_dropoff')),
    );
    expect(pickupLabelRect.bottom, lessThanOrEqualTo(pickupInputRect.top));
    expect(
      destinationLabelRect.bottom,
      lessThanOrEqualTo(destinationInputRect.top),
    );
    expect(
      addButtonRect.center.dy,
      moreOrLessEquals(destinationRect.center.dy - 4, epsilon: 1),
    );
    expect(tester.takeException(), isNull);
  });
}
