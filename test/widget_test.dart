import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/splash/presentation/pages/splash_page.dart';

import 'package:kz_servicos_app/main.dart';

void main() {
  testWidgets('KzServicosApp renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KzServicosApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    // Advance past splash timer to avoid pending timer warning
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
