import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/available_driver.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/widgets/driver_selection_content.dart';

void main() {
  testWidgets('keeps corrected spacing on a tall screen', (tester) async {
    tester.view.physicalSize = const Size(490, 949);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longName = 'Diógenes Willian Carreira de Oliveira';
    const drivers = [
      AvailableDriver(
        driverProfileId: '2753-driver',
        fullName: longName,
        avatarUrl: null,
        averageRating: 4.5,
        totalRatings: 10,
        vehicle: null,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverSelectionContent(
            drivers: drivers,
            onBack: () {},
            onDriverTap: (_) {},
            onRequest: (_) {},
            onQuotation: () {},
          ),
        ),
      ),
    );

    final search = tester.getRect(find.byKey(const Key('driver_search')));
    expect(search.height, greaterThanOrEqualTo(46));

    final sheet = tester.getRect(
      find.byKey(const Key('driver_selection_sheet')),
    );
    final quotation = tester.getRect(find.byKey(const Key('quotation_action')));
    expect(sheet.bottom - quotation.bottom, inInclusiveRange(160, 170));

    final finalActions = tester.getRect(
      find.byKey(const Key('driver_selection_final_actions')),
    );
    expect(finalActions.bottom, quotation.bottom);

    final name = tester.getRect(find.text(longName));
    final category = tester.getRect(find.text('Popular'));
    expect(category.left - name.right, greaterThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the scheduled round-trip driver selection reference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const drivers = [
      AvailableDriver(
        driverProfileId: '1145-driver',
        fullName: 'Motorista Teste',
        avatarUrl: null,
        averageRating: 4.9,
        totalRatings: 48,
        vehicle: null,
      ),
      AvailableDriver(
        driverProfileId: '1153-driver',
        fullName: 'Motorista Teste',
        avatarUrl: null,
        averageRating: 4.5,
        totalRatings: 21,
        vehicle: null,
      ),
      AvailableDriver(
        driverProfileId: '1785-driver',
        fullName: 'Motorista Teste',
        avatarUrl: null,
        averageRating: 4.8,
        totalRatings: 36,
        vehicle: null,
      ),
      AvailableDriver(
        driverProfileId: '1987-driver',
        fullName: 'Motorista Teste',
        avatarUrl: null,
        averageRating: 4.4,
        totalRatings: 17,
        vehicle: null,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverSelectionContent(
            drivers: drivers,
            sendingDriverId: '1153-driver',
            mapBackground: const ColoredBox(color: Color(0xFFF2F3F5)),
            onBack: () {},
            onDriverTap: (_) {},
            onRequest: (_) {},
            onQuotation: () {},
          ),
        ),
      ),
    );

    expect(find.text('Selecionar Motorista'), findsOneWidget);
    expect(find.text('Pesquisar motorista por nome ou tag'), findsOneWidget);
    expect(find.text('Motorista Teste'), findsNWidgets(4));
    expect(find.text('Luxo'), findsNWidgets(2));
    expect(find.text('Popular'), findsNWidgets(2));
    expect(find.text('Solicitar'), findsNWidgets(3));
    expect(find.text('A aguardar\naceitação do motorista'), findsOneWidget);
    expect(find.text('Ver todos...'), findsOneWidget);
    expect(find.text('Cotação'), findsOneWidget);
    expect(
      find.text('Deixe que a nossa equipa escolha o melhor motorista.'),
      findsOneWidget,
    );

    final panel = tester.getRect(
      find.byKey(const Key('driver_selection_sheet')),
    );
    expect(panel.height, closeTo(844 * .72, 1));
    expect(panel.top, closeTo(844 * .28, 1));
    final search = tester.getRect(find.byKey(const Key('driver_search')));
    final list = tester.getRect(find.byKey(const Key('driver_list_card')));
    expect(search.bottom, lessThan(list.top));
  });
}
