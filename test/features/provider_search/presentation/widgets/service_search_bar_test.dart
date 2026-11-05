import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/presentation/widgets/service_search_bar.dart';

const _plumber = ServiceCategory(
  id: 'c-plumber',
  name: 'Canalizador',
  slug: 'plumber',
  description: 'Fugas, torneiras e canalizações',
  icon: Icons.plumbing,
  color: Colors.blue,
);
const _maid = ServiceCategory(
  id: 'c-maid',
  name: 'Empregada doméstica',
  slug: 'diarista',
  description: 'Limpeza e arrumação da casa',
  icon: Icons.cleaning_services,
  color: Colors.green,
);

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<ServiceCategory> onSelected,
  VoidCallback? onCleared,
  List<ServiceCategory> categories = const [_plumber, _maid],
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ServiceSearchBar(
        categories: categories,
        onSelected: onSelected,
        onCleared: onCleared,
      ),
    ),
  ),
);

void main() {
  testWidgets('asks "Que serviço procura?" and shows no suggestions yet', (
    tester,
  ) async {
    await _pump(tester, onSelected: (_) {});

    expect(find.text('Que serviço procura?'), findsOneWidget);
    expect(find.text('Canalizador'), findsNothing);
  });

  testWidgets('typing "canal" suggests the plumber with icon and description', (
    tester,
  ) async {
    await _pump(tester, onSelected: (_) {});

    await tester.enterText(
      find.byKey(const Key('service_search_field')),
      'canal',
    );
    await tester.pump();

    expect(find.text('Canalizador'), findsOneWidget);
    expect(find.text('Fugas, torneiras e canalizações'), findsOneWidget);
    expect(find.byIcon(Icons.plumbing), findsOneWidget);
    expect(find.text('Empregada doméstica'), findsNothing);
  });

  testWidgets('ignores accents and case: "DOMESTICA" finds the maid', (
    tester,
  ) async {
    await _pump(tester, onSelected: (_) {});

    await tester.enterText(
      find.byKey(const Key('service_search_field')),
      'DOMESTICA',
    );
    await tester.pump();

    expect(find.text('Empregada doméstica'), findsOneWidget);
  });

  testWidgets('tapping a suggestion selects it, fills the field and closes', (
    tester,
  ) async {
    ServiceCategory? picked;
    await _pump(tester, onSelected: (c) => picked = c);

    await tester.enterText(
      find.byKey(const Key('service_search_field')),
      'canal',
    );
    // A lista abre com uma animação (AnimatedSize, 220 ms): o 1.º frame
    // constrói e arranca a animação, o 2.º deixa-a terminar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('suggestion-c-plumber')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(picked, _plumber);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('service_search_field')))
          .controller!
          .text,
      'Canalizador',
    );
    // A lista fecha: a descrição da sugestão já não aparece.
    expect(find.text('Fugas, torneiras e canalizações'), findsNothing);
  });

  testWidgets('says so when nothing matches', (tester) async {
    await _pump(tester, onSelected: (_) {});

    await tester.enterText(
      find.byKey(const Key('service_search_field')),
      'astronauta',
    );
    await tester.pump();

    expect(find.text('Nenhum serviço encontrado'), findsOneWidget);
  });

  testWidgets('the clear button empties the field and notifies', (
    tester,
  ) async {
    var cleared = 0;
    await _pump(tester, onSelected: (_) {}, onCleared: () => cleared++);

    await tester.enterText(
      find.byKey(const Key('service_search_field')),
      'canal',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(cleared, 1);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('service_search_field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Canalizador'), findsNothing);
  });

  testWidgets('suggestions appear once the categories finish loading', (
    tester,
  ) async {
    late StateSetter update;
    var categories = const <ServiceCategory>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return ServiceSearchBar(
                categories: categories,
                onSelected: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('service_search_field')),
      'canal',
    );
    await tester.pump();
    expect(find.text('Canalizador'), findsNothing);

    update(() => categories = const [_plumber]);
    await tester.pump();

    expect(find.text('Canalizador'), findsOneWidget);
  });
}
