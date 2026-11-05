import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/products/data/models/product.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/checkout_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_orders_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/products_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/pages/checkout_page.dart';
import 'package:kz_servicos_app/features/products/presentation/pages/order_detail_page.dart';
import 'package:kz_servicos_app/features/products/presentation/pages/products_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProductRepository {}

const _agua = Product(
  id: 'p1',
  slug: 'agua-20l',
  name: 'Água 20 L',
  description: 'Garrafão de água potável',
  unitLabel: 'garrafão',
  price: 1200,
);

ProductOrder _order(ProductOrderStatus status) => ProductOrder(
  id: 'o1',
  status: status,
  deliveryAddress: 'Talatona, Luanda',
  contactPhone: '+244923000001',
  paymentMethod: 'debit',
  subtotal: 2400,
  deliveryFee: 1000,
  total: 3400,
  createdAt: DateTime.utc(2026, 11, 5, 10),
  items: const [
    ProductOrderItem(
      productId: 'p1',
      productName: 'Água 20 L',
      unitPrice: 1200,
      quantity: 2,
      lineTotal: 2400,
    ),
  ],
);

void main() {
  late _MockRepo repo;
  late StreamController<void> changes;

  setUp(() {
    repo = _MockRepo();
    changes = StreamController<void>.broadcast();
    when(() => repo.orderChanges()).thenAnswer((_) => changes.stream);
    when(() => repo.fetchProfilePhone()).thenAnswer((_) async => null);
    registerFallbackValue(const Cart());
    registerFallbackValue(
      const CheckoutForm(address: 'x', phone: '1', paymentMethod: 'cash'),
    );
  });

  tearDown(() => changes.close());

  Widget host(Widget child, {ProductsCubit? products, CheckoutCubit? checkout}) {
    final productsCubit = products ?? ProductsCubit(repository: repo);
    return RepositoryProvider<ProductRepository>.value(
      value: repo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider(create: (_) => ProductOrdersCubit(repository: repo)),
          BlocProvider(
            create: (_) => checkout ?? CheckoutCubit(repository: repo),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => child),
              GoRoute(
                path: '/products/success/:orderId',
                builder: (_, state) =>
                    Text('sucesso ${state.pathParameters['orderId']}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('ProductsPage', () {
    testWidgets('mostra o catálogo com preço em Kz e adiciona ao carrinho', (
      tester,
    ) async {
      when(() => repo.fetchProducts()).thenAnswer((_) async => [_agua]);
      when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => 1000);

      await tester.pumpWidget(host(const ProductsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Água 20 L'), findsOneWidget);
      expect(find.text('1.200,00 Kz / garrafão'), findsOneWidget);
      expect(find.byKey(const Key('products_cart_bar')), findsNothing);

      await tester.tap(find.byKey(const Key('stepper_add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepper_plus')));
      await tester.pumpAndSettle();

      expect(find.text('Ver carrinho · 2 itens'), findsOneWidget);
      expect(find.text('2.400,00 Kz'), findsOneWidget);
    });

    testWidgets('erro mostra mensagem e "Tentar novamente"', (tester) async {
      when(() => repo.fetchProducts()).thenThrow(Exception('rede'));
      when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => null);

      await tester.pumpWidget(host(const ProductsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Erro ao carregar os produtos'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('catálogo vazio mostra estado vazio', (tester) async {
      when(() => repo.fetchProducts()).thenAnswer((_) async => []);
      when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => null);

      await tester.pumpWidget(host(const ProductsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Sem produtos disponíveis'), findsOneWidget);
    });
  });

  group('CheckoutPage', () {
    testWidgets('campos obrigatórios vazios não chamam o servidor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final products = ProductsCubit(repository: repo)
        ..setQuantity(_agua, 2);
      await tester.pumpWidget(host(const CheckoutPage(), products: products));
      await tester.pumpAndSettle();

      expect(find.text('A confirmar'), findsOneWidget); // taxa desconhecida
      await tester.tap(find.text('Fazer pedido'));
      await tester.pumpAndSettle();

      expect(find.text('Indique a morada de entrega'), findsOneWidget);
      expect(find.text('Indique um telemóvel de contacto'), findsOneWidget);
      verifyNever(
        () => repo.createOrder(
          cart: any(named: 'cart'),
          form: any(named: 'form'),
        ),
      );
    });

    testWidgets('envia o pedido com telemóvel em E.164 e pagamento escolhido', (
      tester,
    ) async {
      when(
        () => repo.createOrder(
          cart: any(named: 'cart'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) async => 'novo-pedido');
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final products = ProductsCubit(repository: repo)
        ..setQuantity(_agua, 2);
      await tester.pumpWidget(host(const CheckoutPage(), products: products));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('checkout_address')),
        'Talatona, Luanda',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
        find.byKey(const Key('checkout_phone')),
        '923000001',
      );
      await tester.tap(find.byKey(const Key('payment_debit')));
      await tester.pump();
      await tester.tap(find.text('Fazer pedido'));
      await tester.pump();

      final captured = verify(
        () => repo.createOrder(
          cart: captureAny(named: 'cart'),
          form: captureAny(named: 'form'),
        ),
      ).captured;
      expect((captured[0] as Cart).itemCount, 2);
      final form = captured[1] as CheckoutForm;
      expect(form.phoneE164, '+244923000001');
      expect(form.paymentMethod, 'debit');
      expect(form.cleanAddress, 'Talatona, Luanda');

      await tester.pumpAndSettle();
      expect(find.text('sucesso novo-pedido'), findsOneWidget);
      expect(products.state.cart.isEmpty, isTrue);
    });
  });

  group('OrderDetailPage', () {
    Future<void> pumpDetail(WidgetTester tester, ProductOrderStatus s) async {
      when(() => repo.fetchOrders()).thenAnswer((_) async => [_order(s)]);
      await tester.pumpWidget(host(const OrderDetailPage(orderId: 'o1')));
      await tester.pumpAndSettle();
    }

    testWidgets('pendente: mostra linha de estado, itens e botão cancelar', (
      tester,
    ) async {
      await pumpDetail(tester, ProductOrderStatus.pending);
      expect(find.byKey(const Key('order_timeline')), findsOneWidget);
      expect(find.text('2× Água 20 L'), findsOneWidget);
      expect(find.text('3.400,00 Kz'), findsOneWidget);
      expect(find.text('+244 923 000 001'), findsOneWidget);
      expect(find.text('Multicaixa / cartão de débito'), findsOneWidget);
      expect(find.byKey(const Key('order_cancel')), findsOneWidget);
    });

    testWidgets('confirmado: sem botão cancelar', (tester) async {
      await pumpDetail(tester, ProductOrderStatus.confirmed);
      expect(find.byKey(const Key('order_cancel')), findsNothing);
    });

    testWidgets('estado muda em tempo real quando o servidor avisa', (
      tester,
    ) async {
      await pumpDetail(tester, ProductOrderStatus.pending);
      expect(find.byKey(const Key('order_cancel')), findsOneWidget);

      when(() => repo.fetchOrders()).thenAnswer(
        (_) async => [_order(ProductOrderStatus.outForDelivery)],
      );
      changes.add(null);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order_cancel')), findsNothing);
      expect(find.text('A caminho'), findsWidgets);
    });

    testWidgets('cancelado: mostra motivo e esconde a linha de estado', (
      tester,
    ) async {
      when(() => repo.fetchOrders()).thenAnswer(
        (_) async => [
          ProductOrder(
            id: 'o1',
            status: ProductOrderStatus.cancelled,
            deliveryAddress: 'Viana',
            paymentMethod: 'cash',
            subtotal: 0,
            deliveryFee: 0,
            total: 0,
            cancelReason: 'Enganei-me',
            createdAt: DateTime.utc(2026, 11, 5),
          ),
        ],
      );
      await tester.pumpWidget(host(const OrderDetailPage(orderId: 'o1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Motivo: Enganei-me'), findsOneWidget);
      expect(find.byKey(const Key('order_timeline')), findsNothing);
    });

    testWidgets('cancelar: diálogo com motivo chama a RPC e mostra aviso', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var cancelled = false;
      when(() => repo.fetchOrders()).thenAnswer(
        (_) async => [
          _order(
            cancelled
                ? ProductOrderStatus.cancelled
                : ProductOrderStatus.pending,
          ),
        ],
      );
      when(
        () => repo.cancelOrder('o1', reason: any(named: 'reason')),
      ).thenAnswer((_) async => cancelled = true);
      await tester.pumpWidget(host(const OrderDetailPage(orderId: 'o1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('order_cancel')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('cancel_reason')),
        'Enganei-me',
      );
      await tester.tap(find.byKey(const Key('cancel_confirm')));
      await tester.pumpAndSettle();

      verify(() => repo.cancelOrder('o1', reason: 'Enganei-me')).called(1);
      expect(tester.takeException(), isNull);
      expect(find.text('Pedido cancelado.'), findsOneWidget);
      expect(find.byKey(const Key('order_cancel')), findsNothing);
    });

    testWidgets('cancelar: "Manter pedido" não chama a RPC', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      when(
        () => repo.fetchOrders(),
      ).thenAnswer((_) async => [_order(ProductOrderStatus.pending)]);
      await tester.pumpWidget(host(const OrderDetailPage(orderId: 'o1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('order_cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manter pedido'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repo.cancelOrder(any(), reason: any(named: 'reason')),
      );
      expect(find.byKey(const Key('order_cancel')), findsOneWidget);
    });

    testWidgets('pedido inexistente → "Pedido não encontrado"', (tester) async {
      when(() => repo.fetchOrders()).thenAnswer((_) async => []);
      await tester.pumpWidget(host(const OrderDetailPage(orderId: 'zzz')));
      await tester.pumpAndSettle();
      expect(find.text('Pedido não encontrado'), findsOneWidget);
    });
  });
}
