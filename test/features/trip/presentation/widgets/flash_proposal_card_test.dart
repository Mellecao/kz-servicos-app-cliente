import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/flash_proposal.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/flash_proposal_card.dart';

void main() {
  testWidgets('renders name, vehicle and price', (tester) async {
    final p = FlashProposal(
      candidateId: 'c',
      tripId: 't',
      driverProfileId: 'd',
      driverName: 'João',
      driverPhotoUrl: null,
      vehicleLabel: 'Onix Prata',
      offeredPrice: 55.5,
      createdAt: DateTime.now(),
      etaMinutes: 12,
      driverRatingAvg: 4.8,
      driverFinishedTrips: 100,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlashProposalCard(proposal: p, onTap: () {}),
      ),
    ));
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Onix Prata'), findsOneWidget);
    expect(find.textContaining('R\$'), findsOneWidget);
    expect(find.text('12 min até você'), findsOneWidget);
  });

  testWidgets('shows ETA indisponível when etaMinutes is null',
      (tester) async {
    final p = FlashProposal(
      candidateId: 'c',
      tripId: 't',
      driverProfileId: 'd',
      driverName: 'Maria',
      driverPhotoUrl: null,
      vehicleLabel: 'Fiat Uno',
      offeredPrice: 40,
      createdAt: DateTime.now(),
      etaMinutes: null,
      driverRatingAvg: null,
      driverFinishedTrips: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlashProposalCard(proposal: p, onTap: () {}),
      ),
    ));
    expect(find.text('ETA indisponível'), findsOneWidget);
  });

  testWidgets('invokes onTap when tapped', (tester) async {
    var tapped = false;
    final p = FlashProposal(
      candidateId: 'c',
      tripId: 't',
      driverProfileId: 'd',
      driverName: 'X',
      driverPhotoUrl: null,
      vehicleLabel: 'Y Z',
      offeredPrice: 10,
      createdAt: DateTime.now(),
      etaMinutes: 5,
      driverRatingAvg: null,
      driverFinishedTrips: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlashProposalCard(proposal: p, onTap: () => tapped = true),
      ),
    ));
    await tester.tap(find.byType(FlashProposalCard));
    expect(tapped, isTrue);
  });
}
