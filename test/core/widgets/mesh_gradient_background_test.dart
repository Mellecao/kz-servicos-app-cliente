import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/mesh_gradient_background.dart';

void main() {
  group('MeshGradientBackground', () {
    testWidgets('should render CustomPaint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeshGradientBackground(
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should accept colors parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MeshGradientBackground(
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final widget = tester.widget<MeshGradientBackground>(
        find.byType(MeshGradientBackground),
      );
      expect(widget.colors.length, 4);
    });

    testWidgets('should fill available space', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: MeshGradientBackground(
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(MeshGradientBackground),
      );
      expect(renderBox.size.width, 400);
      expect(renderBox.size.height, 800);
    });
  });
}
