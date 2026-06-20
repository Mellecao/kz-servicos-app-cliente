import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/searching_driver_popup.dart';

void main() {
  testWidgets('shows go home action when enabled', (tester) async {
    var wentHome = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchingDriverSheet(
            onCancel: () {},
            onGoHome: () => wentHome = true,
          ),
        ),
      ),
    );

    expect(find.text('Ir para home'), findsOneWidget);

    await tester.tap(find.text('Ir para home'));
    expect(wentHome, isTrue);
  });

  testWidgets('hides go home action when disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SearchingDriverSheet(onCancel: () {})),
      ),
    );

    expect(find.text('Ir para home'), findsNothing);
  });
}
