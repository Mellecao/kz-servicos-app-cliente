import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/driver_candidate.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_selection_panel.dart';

void main() {
  testWidgets('detalhes do motorista mostram foto de perfil e fotos extras', (
    tester,
  ) async {
    const candidate = DriverCandidate(
      candidateId: 'candidate-1',
      tripId: 'trip-1',
      driverProfileId: 'driver-1',
      driverName: 'Joao Silva',
      avatarUrl: 'https://example.com/profile.jpg',
      photoUrls: [
        'https://example.com/driver-public.jpg',
        'https://example.com/car.jpg',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverSelectionPanel(
            candidates: const [candidate],
            onDriverAccepted: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('DETALHES DO MOTORISTA'));
    await tester.pumpAndSettle();

    expect(find.text('Fotos do motorista e do carro'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
  });
}
