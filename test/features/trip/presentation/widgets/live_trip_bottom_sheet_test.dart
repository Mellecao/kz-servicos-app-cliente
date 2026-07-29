import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_execution_stage.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/live_trip_bottom_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LiveTripBottomSheet', () {
    testWidgets('renders driver name, ETA, distance and stage label', (tester) async {
      await tester.pumpWidget(_wrap(LiveTripBottomSheet(
        driverName: 'João Silva',
        driverPhotoUrl: null,
        vehicleLabel: 'Onix Prata',
        etaMinutes: 7,
        distanceMeters: 2400,
        stage: TripExecutionStage.toPickup,
        onCall: () {},
        onChat: () {},
      )));

      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Onix Prata'), findsOneWidget);
      expect(find.textContaining('7 min'), findsOneWidget);
      expect(find.textContaining('2,4 km'), findsOneWidget);
      expect(find.text('Motorista a caminho'), findsOneWidget);
    });

    testWidgets('renders "-" for null ETA and null distance', (tester) async {
      await tester.pumpWidget(_wrap(LiveTripBottomSheet(
        driverName: 'X',
        driverPhotoUrl: null,
        vehicleLabel: 'Y',
        etaMinutes: null,
        distanceMeters: null,
        stage: TripExecutionStage.toDestination,
        onCall: () {},
        onChat: () {},
      )));

      expect(find.textContaining('—'), findsWidgets);
      expect(find.text('A caminho do destino'), findsOneWidget);
    });

    testWidgets('shows Cancel button when onCancel != null', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(_wrap(LiveTripBottomSheet(
        driverName: 'A', driverPhotoUrl: null, vehicleLabel: 'B',
        etaMinutes: 3, distanceMeters: 500,
        stage: TripExecutionStage.toPickup,
        onCall: () {}, onChat: () {},
        onCancel: () => cancelled = true,
      )));

      final btn = find.text('Cancelar');
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      expect(cancelled, isTrue);
    });

    testWidgets('hides Cancel button when onCancel is null', (tester) async {
      await tester.pumpWidget(_wrap(LiveTripBottomSheet(
        driverName: 'A', driverPhotoUrl: null, vehicleLabel: 'B',
        etaMinutes: 3, distanceMeters: 500,
        stage: TripExecutionStage.toDestination,
        onCall: () {}, onChat: () {},
      )));

      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('Call and Chat buttons invoke callbacks', (tester) async {
      var called = false, chatted = false;
      await tester.pumpWidget(_wrap(LiveTripBottomSheet(
        driverName: 'A', driverPhotoUrl: null, vehicleLabel: 'B',
        etaMinutes: 3, distanceMeters: 500,
        stage: TripExecutionStage.toPickup,
        onCall: () => called = true,
        onChat: () => chatted = true,
      )));

      await tester.tap(find.byIcon(Icons.phone));
      expect(called, isTrue);
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      expect(chatted, isTrue);
    });

    testWidgets('shows initials fallback when driverPhotoUrl is null', (tester) async {
      await tester.pumpWidget(_wrap(LiveTripBottomSheet(
        driverName: 'Maria', driverPhotoUrl: null, vehicleLabel: 'X',
        etaMinutes: 1, distanceMeters: 100,
        stage: TripExecutionStage.toPickup,
        onCall: () {}, onChat: () {},
      )));

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('badge changes with stage', (tester) async {
      for (final s in [
        TripExecutionStage.toStop,
        TripExecutionStage.waitingAtStop,
        TripExecutionStage.returning,
        TripExecutionStage.waitingForReturn,
      ]) {
        await tester.pumpWidget(_wrap(LiveTripBottomSheet(
          driverName: 'A', driverPhotoUrl: null, vehicleLabel: 'B',
          etaMinutes: 1, distanceMeters: 100,
          stage: s,
          onCall: () {}, onChat: () {},
        )));
        expect(find.text(s.label), findsOneWidget);
      }
    });
  });
}
