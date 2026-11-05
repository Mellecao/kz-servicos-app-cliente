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
}
