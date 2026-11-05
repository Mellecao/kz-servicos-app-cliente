import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/routes/persistent_app_shell.dart';

void main() {
  testWidgets('hides the "Agendamentos" tab when trips are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PersistentAppShell(
          currentIndex: 0,
          tripsEnabled: false,
          onSelect: (_) {},
          child: const Text('page'),
        ),
      ),
    );

    expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });

  testWidgets('keeps the "Agendamentos" tab when trips are on', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PersistentAppShell(
          currentIndex: 0,
          onSelect: (_) {},
          child: const Text('page'),
        ),
      ),
    );

    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.local_taxi_rounded), findsOneWidget);
  });

  testWidgets('keeps the same bottom menu element while switching tabs', (
    tester,
  ) async {
    var index = 0;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PersistentAppShell(
              currentIndex: index,
              onSelect: (_) {},
              child: Text('page-$index'),
            );
          },
        ),
      ),
    );

    final menuFinder = find.byKey(const ValueKey('persistent_bottom_nav'));
    final originalElement = tester.element(menuFinder);

    update(() => index = 3);
    await tester.pump();

    expect(tester.element(menuFinder), same(originalElement));
    expect(find.text('page-3'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.person_rounded)).color,
      AppColors.highlight,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.local_taxi_rounded)).color,
      Colors.white,
    );
  });
}
