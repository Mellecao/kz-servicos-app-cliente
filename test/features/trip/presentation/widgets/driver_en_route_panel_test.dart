import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/mock_driver.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_en_route_panel.dart';

void main() {
  testWidgets('shows easy cancel action while driver is en route', (
    tester,
  ) async {
    var cancelled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverEnRoutePanel(
            driver: MockDriver(
              id: 'driver-1',
              name: 'Joao Silva',
              initials: 'JS',
              carModel: 'Sedan',
              carColor: 'Preto',
              licensePlate: 'ABC-1234',
              rating: 4.9,
              description: 'Motorista verificado',
              rg: '123',
              birthDate: DateTime(1990),
              extras: const [],
            ),
            etaMinutes: 8,
            distanceMeters: 2400,
            onToggleExpand: () {},
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text('Cancelar'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    expect(cancelled, isTrue);
  });
}
