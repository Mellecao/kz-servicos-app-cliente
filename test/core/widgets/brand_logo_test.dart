import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/constants/app_brand.dart';
import 'package:kz_servicos_app/core/widgets/brand_logo.dart';

String _assetOf(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image));
  return (image.image as AssetImage).assetName;
}

void main() {
  group('AppBrand', () {
    test('name is "Só Serviços"', () {
      expect(AppBrand.name, 'Só Serviços');
    });

    test('tagline is "Serviços de apoio ao domicílio"', () {
      expect(AppBrand.tagline, 'Serviços de apoio ao domicílio');
    });
  });

  group('BrandLogo', () {
    testWidgets('onDark uses the white logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BrandLogo(onDark: true)),
      );

      expect(_assetOf(tester), 'assets/brand/logo-horizontal-white.png');
    });

    testWidgets('on light background uses the dark logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BrandLogo(onDark: false)),
      );

      expect(_assetOf(tester), 'assets/brand/logo-horizontal-dark.png');
    });

    testWidgets('respects the requested width', (tester) async {
      // Center dá restrições soltas, como no uso real (o `home` do
      // MaterialApp impõe o tamanho do ecrã e ignoraria o width).
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: BrandLogo(onDark: true, width: 180)),
        ),
      );

      expect(tester.getSize(find.byType(Image)).width, 180);
    });

    testWidgets('exposes the brand name for accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BrandLogo(onDark: true)),
      );

      expect(find.bySemanticsLabel('Só Serviços'), findsOneWidget);
    });
  });
}
