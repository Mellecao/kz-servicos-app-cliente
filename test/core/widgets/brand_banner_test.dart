import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/core/widgets/brand_banner.dart';
import 'package:kz_servicos_app/core/widgets/brand_logo.dart';

Widget _host({required double width, required double height}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: const BrandBanner(
            title: 'Precisa de ajuda em casa?',
            subtitle: 'Peça um profissional em poucos toques.',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('BrandBanner', () {
    testWidgets('shows title, subtitle and the brand mark', (tester) async {
      await tester.pumpWidget(_host(width: 360, height: 110));

      expect(find.text('Precisa de ajuda em casa?'), findsOneWidget);
      expect(find.text('Peça um profissional em poucos toques.'), findsOneWidget);

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, BrandLogo.iconAsset);
    });

    testWidgets('does not overflow at the smallest carousel size',
        (tester) async {
      // O carrossel da home usa alturas entre 92 e 164 px.
      await tester.pumpWidget(_host(width: 320, height: 92));

      expect(tester.takeException(), isNull);
    });

    testWidgets('uses white title text on the dark backdrop', (tester) async {
      await tester.pumpWidget(_host(width: 360, height: 110));

      final title = tester.widget<Text>(find.text('Precisa de ajuda em casa?'));
      expect(title.style?.color, Colors.white);
    });
  });
}
