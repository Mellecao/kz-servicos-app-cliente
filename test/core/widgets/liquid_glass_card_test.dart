import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/liquid_glass_card.dart';

void main() {
  group('LiquidGlassCard', () {
    testWidgets('should render child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                LiquidGlassCard(
                  child: Text('Glass Content'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Glass Content'), findsOneWidget);
    });

    testWidgets('should contain BackdropFilter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                LiquidGlassCard(
                  child: Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('should apply border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                LiquidGlassCard(
                  borderRadius: 32,
                  child: Text('Content'),
                ),
              ],
            ),
          ),
        ),
      );
      final widget = tester.widget<LiquidGlassCard>(
        find.byType(LiquidGlassCard),
      );
      expect(widget.borderRadius, 32);
    });
  });
}
