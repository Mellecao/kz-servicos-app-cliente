import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';

void main() {
  testWidgets('only the active menu icon is yellow and has no circle or glow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripBottomNav(selectedIndex: 1, onItemSelected: (_) {}),
        ),
      ),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.calendar_month_rounded)).color,
      AppColors.highlight,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.local_taxi_rounded)).color,
      Colors.white,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.work_rounded)).color,
      Colors.white,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.person_rounded)).color,
      Colors.white,
    );

    final selectedDecoration = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((decoration) => decoration.shape == BoxShape.circle);
    expect(selectedDecoration.color, Colors.transparent);
    expect(selectedDecoration.boxShadow, isEmpty);
  });

  group('with trips on (trips_enabled=true)', () {
    testWidgets('shows the four tabs and reports branch indexes 0..3', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripBottomNav(selectedIndex: 0, onItemSelected: taps.add),
          ),
        ),
      );

      for (final icon in [
        Icons.local_taxi_rounded,
        Icons.calendar_month_rounded,
        Icons.work_rounded,
        Icons.person_rounded,
      ]) {
        await tester.tap(find.byIcon(icon));
      }

      expect(taps, [0, 1, 2, 3]);
    });

    testWidgets('shows the scheduled-trips badge on the calendar tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripBottomNav(
              selectedIndex: 0,
              scheduledCount: 2,
              onItemSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('+2'), findsOneWidget);
    });
  });

  group('with trips off (trips_enabled=false)', () {
    Widget nav({
      required List<int> taps,
      int selectedIndex = 0,
      int scheduledCount = 0,
    }) => MaterialApp(
      home: Scaffold(
        body: TripBottomNav(
          selectedIndex: selectedIndex,
          scheduledCount: scheduledCount,
          tripsEnabled: false,
          onItemSelected: taps.add,
        ),
      ),
    );

    testWidgets('hides the "Agendamentos" tab and keeps three', (tester) async {
      await tester.pumpWidget(nav(taps: []));

      expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.work_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('still reports the shell branch index of each tab', (
      tester,
    ) async {
      final taps = <int>[];
      await tester.pumpWidget(nav(taps: taps));

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.tap(find.byIcon(Icons.work_rounded));
      await tester.tap(find.byIcon(Icons.person_rounded));

      // Buscar = ramo 0, Serviços = ramo 2, Perfil = ramo 3 (o 1 está oculto).
      expect(taps, [0, 2, 3]);
    });

    testWidgets('highlights the tab of the selected branch', (tester) async {
      await tester.pumpWidget(nav(taps: [], selectedIndex: 3));

      expect(
        tester.widget<Icon>(find.byIcon(Icons.person_rounded)).color,
        AppColors.highlight,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.work_rounded)).color,
        Colors.white,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.search_rounded)).color,
        Colors.white,
      );
    });

    testWidgets('never shows the scheduled-trips badge', (tester) async {
      await tester.pumpWidget(nav(taps: [], scheduledCount: 5));

      expect(find.text('+5'), findsNothing);
    });
  });
}
