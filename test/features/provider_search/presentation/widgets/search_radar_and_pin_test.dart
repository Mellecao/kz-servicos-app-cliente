import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/provider_pin_icon.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/search_radar.dart';

void main() {
  testWidgets('radar says "A procurar prestadores próximos…" and animates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SearchRadar())),
    );

    expect(find.text('A procurar prestadores próximos…'), findsOneWidget);
    expect(find.byKey(const Key('search_radar')), findsOneWidget);

    // Animação contínua: avançar o relógio não pode lançar erros.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('radar lets map gestures through', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SearchRadar())),
    );
    final ignore = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byKey(const Key('search_radar')),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('the pin icon renders a PNG', (tester) async {
    final bytes = await tester.runAsync<Uint8List>(
      () => ProviderPinIcon.renderPng(Icons.plumbing),
    );

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100));
    // Assinatura PNG.
    expect(bytes.sublist(0, 4), [137, 80, 78, 71]);
  });
}
