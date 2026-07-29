import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_type_choice_sheet.dart';

void main() {
  testWidgets('renders both options and returns "flash" on tap',
      (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () async {
          picked = await showModalBottomSheet<String>(
            context: ctx,
            builder: (_) => const TripTypeChoiceSheet(),
          );
        },
        child: const Text('open'),
      );
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Preciso de uma viagem agora'), findsOneWidget);
    expect(find.text('Quero agendar uma viagem'), findsOneWidget);
    await tester.tap(find.text('Preciso de uma viagem agora'));
    await tester.pumpAndSettle();
    expect(picked, 'flash');
  });

  testWidgets('returns "scheduled" when scheduled option is tapped',
      (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
      return ElevatedButton(
        onPressed: () async {
          picked = await showModalBottomSheet<String>(
            context: ctx,
            builder: (_) => const TripTypeChoiceSheet(),
          );
        },
        child: const Text('open'),
      );
    })));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quero agendar uma viagem'));
    await tester.pumpAndSettle();
    expect(picked, 'scheduled');
  });
}
