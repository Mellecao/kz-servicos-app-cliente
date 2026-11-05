import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/products/data/models/product.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/checkout_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_orders_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/products_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProductRepository {}

const _agua = Product(
  id: 'p1',
  slug: 'agua-20l',
  name: 'Água 20 L',
  unitLabel: 'garrafão',
  price: 1200,
);

ProductOrder _order(String id, ProductOrderStatus status) => ProductOrder(
  id: id,
  status: status,
  deliveryAddress: 'Talatona',
  paymentMethod: 'cash',
  subtotal: 1200,
  deliveryFee: 1000,
  total: 2200,
  createdAt: DateTime.utc(2026, 11, 5, 10),
);

const _form = CheckoutForm(
  address: 'Talatona, Luanda',
  phone: '923 000 001',
  paymentMethod: 'cash',
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('ProductsCubit', () {
    blocTest<ProductsCubit, ProductsState>(
      'load: loading → loaded com catálogo e taxa',
      build: () {
        when(() => repo.fetchProducts()).thenAnswer((_) async => [_agua]);
        when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => 1000);
        return ProductsCubit(repository: repo);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProductsState>().having(
          (s) => s.status,
          'status',
          ProductsStatus.loading,
        ),
        isA<ProductsState>()
            .having((s) => s.status, 'status', ProductsStatus.loaded)
            .having((s) => s.products, 'products', [_agua])
            .having((s) => s.deliveryFee, 'fee', 1000),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'load: erro do repositório → error com mensagem em pt-AO',
      build: () {
        when(() => repo.fetchProducts()).thenThrow(Exception('boom'));
        when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => null);
        return ProductsCubit(repository: repo);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ProductsState>().having(
          (s) => s.status,
          'status',
          ProductsStatus.loading,
        ),
        isA<ProductsState>()
            .having((s) => s.status, 'status', ProductsStatus.error)
            .having((s) => s.message, 'message', isNotEmpty),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'setQuantity e clearCart atualizam o carrinho',
      build: () {
        when(() => repo.fetchProducts()).thenAnswer((_) async => [_agua]);
        when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => 1000);
        return ProductsCubit(repository: repo);
      },
      seed: () => const ProductsState(status: ProductsStatus.loaded),
      act: (c) {
        c.setQuantity(_agua, 2);
        c.clearCart();
      },
      verify: (c) => expect(c.state.cart.isEmpty, isTrue),
      expect: () => [
        isA<ProductsState>().having((s) => s.cart.itemCount, 'items', 2),
        isA<ProductsState>().having((s) => s.cart.itemCount, 'items', 0),
      ],
    );

    test('o carrinho sobrevive a uma recarga do catálogo', () async {
      when(() => repo.fetchProducts()).thenAnswer((_) async => [_agua]);
      when(() => repo.fetchDeliveryFee()).thenAnswer((_) async => 1000);
      final cubit = ProductsCubit(repository: repo);
      await cubit.load();
      cubit.setQuantity(_agua, 3);
      await cubit.load();
      expect(cubit.state.cart.quantityOf(_agua), 3);
      await cubit.close();
    });
  });

  group('CheckoutCubit', () {
    final cart = const Cart().withQuantity(_agua, 2);

    setUpAll(() {
      registerFallbackValue(const Cart());
      registerFallbackValue(_form);
    });

    blocTest<CheckoutCubit, CheckoutState>(
      'submit com sucesso: submitting → success(orderId)',
      build: () {
        when(
          () => repo.createOrder(
            cart: any(named: 'cart'),
            form: any(named: 'form'),
          ),
        ).thenAnswer((_) async => 'order-1');
        return CheckoutCubit(repository: repo);
      },
      act: (c) => c.submit(cart, _form),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.submitting,
        ),
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.success)
            .having((s) => s.orderId, 'orderId', 'order-1'),
      ],
    );

    blocTest<CheckoutCubit, CheckoutState>(
      'submit com erro: submitting → failure com mensagem',
      build: () {
        when(
          () => repo.createOrder(
            cart: any(named: 'cart'),
            form: any(named: 'form'),
          ),
        ).thenThrow(Exception('rede'));
        return CheckoutCubit(repository: repo);
      },
      act: (c) => c.submit(cart, _form),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.submitting,
        ),
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.failure)
            .having((s) => s.message, 'message', isNotEmpty),
      ],
    );

    blocTest<CheckoutCubit, CheckoutState>(
      'carrinho vazio ou formulário inválido não chama o servidor',
      build: () => CheckoutCubit(repository: repo),
      act: (c) {
        c.submit(const Cart(), _form);
        c.submit(
          cart,
          const CheckoutForm(address: '', phone: '1', paymentMethod: 'cash'),
        );
      },
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.failure,
        ),
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.failure,
        ),
      ],
      verify: (_) => verifyNever(
        () => repo.createOrder(
          cart: any(named: 'cart'),
          form: any(named: 'form'),
        ),
      ),
    );

    test('ignora um segundo submit enquanto está a enviar', () async {
      final gate = Completer<String>();
      when(
        () => repo.createOrder(
          cart: any(named: 'cart'),
          form: any(named: 'form'),
        ),
      ).thenAnswer((_) => gate.future);
      final cubit = CheckoutCubit(repository: repo);
      unawaited(cubit.submit(cart, _form));
      await Future<void>.delayed(Duration.zero);
      unawaited(cubit.submit(cart, _form));
      gate.complete('o1');
      await Future<void>.delayed(Duration.zero);
      verify(
        () => repo.createOrder(
          cart: any(named: 'cart'),
          form: any(named: 'form'),
        ),
      ).called(1);
      await cubit.close();
    });
  });

  group('ProductOrdersCubit', () {
    late StreamController<void> changes;

    setUp(() {
      changes = StreamController<void>.broadcast();
      when(() => repo.orderChanges()).thenAnswer((_) => changes.stream);
    });

    tearDown(() => changes.close());

    test('load: loading → loaded e fica à escuta do realtime', () async {
      when(
        () => repo.fetchOrders(),
      ).thenAnswer((_) async => [_order('o1', ProductOrderStatus.pending)]);
      final cubit = ProductOrdersCubit(repository: repo);
      final states = <ProductOrdersStatus>[];
      final sub = cubit.stream.listen((s) => states.add(s.status));
      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(states, [
        ProductOrdersStatus.loading,
        ProductOrdersStatus.loaded,
      ]);
      expect(changes.hasListener, isTrue);
      await sub.cancel();
      await cubit.close();
      expect(changes.hasListener, isFalse);
    });

    test('evento realtime recarrega e mostra o novo estado', () async {
      var call = 0;
      when(() => repo.fetchOrders()).thenAnswer((_) async {
        call++;
        return [
          _order(
            'o1',
            call == 1
                ? ProductOrderStatus.pending
                : ProductOrderStatus.confirmed,
          ),
        ];
      });
      final cubit = ProductOrdersCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.orders.single.status, ProductOrderStatus.pending);
      changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.orders.single.status, ProductOrderStatus.confirmed);
      await cubit.close();
    });

    test('falha numa recarga silenciosa mantém os dados anteriores', () async {
      var call = 0;
      when(() => repo.fetchOrders()).thenAnswer((_) async {
        call++;
        if (call > 1) throw Exception('rede');
        return [_order('o1', ProductOrderStatus.pending)];
      });
      final cubit = ProductOrdersCubit(repository: repo);
      await cubit.load();
      changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.status, ProductOrdersStatus.loaded);
      expect(cubit.state.orders, isNotEmpty);
      await cubit.close();
    });

    test('load com erro → error', () async {
      when(() => repo.fetchOrders()).thenThrow(Exception('rede'));
      final cubit = ProductOrdersCubit(repository: repo);
      await cubit.load();
      expect(cubit.state.status, ProductOrdersStatus.error);
      expect(cubit.state.message, isNotEmpty);
      await cubit.close();
    });

    test('cancel: chama a RPC, recarrega e devolve true', () async {
      var cancelled = false;
      when(
        () => repo.cancelOrder('o1', reason: any(named: 'reason')),
      ).thenAnswer((_) async => cancelled = true);
      when(() => repo.fetchOrders()).thenAnswer(
        (_) async => [
          _order(
            'o1',
            cancelled
                ? ProductOrderStatus.cancelled
                : ProductOrderStatus.pending,
          ),
        ],
      );
      final cubit = ProductOrdersCubit(repository: repo);
      await cubit.load();
      final ok = await cubit.cancel('o1', reason: 'Enganei-me');
      expect(ok, isTrue);
      expect(cubit.state.orders.single.status, ProductOrderStatus.cancelled);
      verify(() => repo.cancelOrder('o1', reason: 'Enganei-me')).called(1);
      await cubit.close();
    });

    test('cancel falhado: devolve false e expõe mensagem', () async {
      when(() => repo.fetchOrders()).thenAnswer(
        (_) async => [_order('o1', ProductOrderStatus.pending)],
      );
      when(
        () => repo.cancelOrder('o1', reason: any(named: 'reason')),
      ).thenThrow(Exception('já confirmado'));
      final cubit = ProductOrdersCubit(repository: repo);
      await cubit.load();
      final ok = await cubit.cancel('o1');
      expect(ok, isFalse);
      expect(cubit.state.actionError, isNotNull);
      expect(cubit.state.cancellingId, isNull);
      await cubit.close();
    });
  });
}
