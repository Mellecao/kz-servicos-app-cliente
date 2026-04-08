import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/dust_particles.dart';

void main() {
  group('DustParticles', () {
    testWidgets('should render CustomPaint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DustParticles(
              color: Colors.white,
              scrollOffset: 0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should accept color and scrollOffset', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DustParticles(
              color: Colors.red,
              scrollOffset: 0.5,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final widget = tester.widget<DustParticles>(
        find.byType(DustParticles),
      );
      expect(widget.color, Colors.red);
      expect(widget.scrollOffset, 0.5);
    });
  });
}
