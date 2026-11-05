import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/provider_search_repository.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/provider_details_sheet.dart';

const _provider = ProviderSearchResult(
  providerProfileId: 'p-1',
  fullName: 'Miguel Prestador',
  bio: 'Canalizador com 10 anos de experiência em Luanda.',
  categoryId: 'c-plumber',
  categoryName: 'Canalizador',
  averageRating: 4.8,
  totalRatings: 23,
  priceMin: 5500,
  priceMax: 38500,
  avgResponseMinutes: 18,
  lat: -8.84,
  lng: 13.23,
);

const _category = ServiceCategory(
  id: 'c-plumber',
  name: 'Canalizador',
  slug: 'plumber',
  icon: Icons.plumbing,
  color: Colors.blue,
);

Future<void> _pump(
  WidgetTester tester, {
  ProviderSearchResult provider = _provider,
  Future<String> Function(String description)? onRequest,
  ValueChanged<String>? onViewRequest,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ProviderDetailsSheet(
            provider: provider,
            category: _category,
            onRequest: onRequest ?? (_) async => 'req-1',
            onViewRequest: onViewRequest ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the provider data: name, category, rating, price, time', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Miguel Prestador'), findsOneWidget);
    expect(find.text('Canalizador'), findsOneWidget);
    expect(find.text('MP'), findsOneWidget); // sem foto → iniciais
    expect(find.textContaining('4,8'), findsOneWidget);
    expect(find.textContaining('23 avaliações'), findsOneWidget);
    expect(find.text('5.500 – 38.500 Kz'), findsOneWidget);
    expect(find.text('Responde em ~18 min'), findsOneWidget);
    expect(find.textContaining('10 anos de experiência'), findsOneWidget);
    expect(find.text('Solicitar'), findsOneWidget);
  });

  testWidgets('a provider without bio or reviews still renders', (
    tester,
  ) async {
    await _pump(
      tester,
      provider: const ProviderSearchResult(
        providerProfileId: 'p-2',
        fullName: 'Ana',
        categoryId: 'c-plumber',
        categoryName: 'Canalizador',
        priceMin: 3000,
        priceMax: 3000,
        avgResponseMinutes: 90,
        lat: 0,
        lng: 0,
      ),
    );

    expect(find.text('Novo'), findsOneWidget);
    expect(find.text('Sem avaliações'), findsOneWidget);
    expect(find.text('3.000 Kz'), findsOneWidget);
    expect(find.text('Responde em ~2 h'), findsOneWidget);
  });

  testWidgets('"Solicitar" asks for the description, which is required', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Solicitar'));
    await tester.pump();

    expect(find.byKey(const Key('request_description_field')), findsOneWidget);
    final send = find.widgetWithText(ElevatedButton, 'Enviar pedido');
    expect(tester.widget<ElevatedButton>(send).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('request_description_field')),
      '   ',
    );
    await tester.pump();
    expect(tester.widget<ElevatedButton>(send).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('request_description_field')),
      'Torneira da cozinha a pingar',
    );
    await tester.pump();
    expect(tester.widget<ElevatedButton>(send).onPressed, isNotNull);
  });

  testWidgets('sending confirms and offers to follow the request', (
    tester,
  ) async {
    String? sent;
    String? opened;
    await _pump(
      tester,
      onRequest: (description) async {
        sent = description;
        return 'req-42';
      },
      onViewRequest: (id) => opened = id,
    );

    await tester.tap(find.text('Solicitar'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('request_description_field')),
      'Torneira da cozinha a pingar',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar pedido'));
    await tester.pump();
    await tester.pump();

    expect(sent, 'Torneira da cozinha a pingar');
    expect(find.text('Pedido enviado'), findsOneWidget);
    expect(find.textContaining('Miguel Prestador'), findsOneWidget);

    await tester.tap(find.text('Ver o meu pedido'));
    expect(opened, 'req-42');
  });

  testWidgets('shows the server message as it comes and lets the user retry', (
    tester,
  ) async {
    await _pump(
      tester,
      onRequest: (_) async => throw const ProviderSearchException(
        'Já enviou um pedido a este prestador. Aguarde a proposta dele',
      ),
    );

    await tester.tap(find.text('Solicitar'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('request_description_field')),
      'Torneira',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enviar pedido'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Já enviou um pedido a este prestador. Aguarde a proposta dele',
      ),
      findsOneWidget,
    );
    expect(find.text('Pedido enviado'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Enviar pedido'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('"Voltar" returns to the provider data', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Solicitar'));
    await tester.pump();
    await tester.tap(find.text('Voltar'));
    await tester.pump();

    expect(find.text('5.500 – 38.500 Kz'), findsOneWidget);
    expect(find.byKey(const Key('request_description_field')), findsNothing);
  });
}
