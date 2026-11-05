import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_date_time_panel.dart';

void main() {
  testWidgets('renders as a compact bottom sheet over the map area', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: TripDateTimePanel(onBack: () {}, onConfirm: (_) {}),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const Key('date_time_sheet')));
    expect(rect.bottom, 844);
    expect(rect.top, greaterThan(300));
    expect(rect.height, lessThan(544));
  });

  testWidgets('requires both scheduled date and time before advancing', (
    tester,
  ) async {
    DateTime? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripDateTimePanel(
            onBack: () {},
            onConfirm: (value) => confirmed = value,
          ),
        ),
      ),
    );

    expect(find.text('Data e Hora'), findsOneWidget);
    expect(find.text('Avançar'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Avançar')).onPressed,
      isNull,
    );

    await tester.tap(find.text('Selecionar Data...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selecionar Hora...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Avançar'), findsOneWidget);
    await tester.tap(find.text('Avançar'));
    expect(confirmed, isNotNull);
  });
}
