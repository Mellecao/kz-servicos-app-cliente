import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/products/data/models/product.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';

const _agua = Product(
  id: 'p1',
  slug: 'agua-20l',
  name: 'Água 20 L',
  unitLabel: 'garrafão',
  price: 1200,
);
const _gelo = Product(
  id: 'p2',
  slug: 'gelo-cubos',
  name: 'Gelo em cubos',
  unitLabel: 'saco',
  price: 1500,
);

void main() {
  group('Product.fromJson', () {
    test('converte preço numérico e texto', () {
      final a = Product.fromJson({
        'id': 'p1',
        'slug': 'agua-20l',
        'name': 'Água 20 L',
        'description': 'Garrafão',
        'unit_label': 'garrafão',
        'price': 1200,
        'image_url': null,
        'sort_order': 40,
      });
      expect(a.price, 1200.0);
      expect(a.description, 'Garrafão');
      final b = Product.fromJson({
        'id': 'p2',
        'slug': 'x',
        'name': 'X',
        'unit_label': 'saco',
        'price': '1500.50',
      });
      expect(b.price, 1500.5);
      expect(b.description, isNull);
    });
  });

  group('Cart', () {
    test('começa vazio', () {
      const cart = Cart();
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0);
    });

    test('define quantidades e calcula subtotal e contagem', () {
      final cart = const Cart().withQuantity(_agua, 2).withQuantity(_gelo, 3);
      expect(cart.quantityOf(_agua), 2);
      expect(cart.itemCount, 5);
      expect(cart.subtotal, 2 * 1200 + 3 * 1500);
      expect(cart.lines.length, 2);
    });

    test('quantidade 0 remove a linha', () {
      final cart = const Cart().withQuantity(_agua, 2).withQuantity(_agua, 0);
      expect(cart.isEmpty, isTrue);
      expect(cart.quantityOf(_agua), 0);
    });

    test('limita a 99 unidades por produto e ignora negativos', () {
      expect(const Cart().withQuantity(_agua, 150).quantityOf(_agua), 99);
      expect(const Cart().withQuantity(_agua, -3).isEmpty, isTrue);
    });

    test('total soma a taxa de entrega', () {
      final cart = const Cart().withQuantity(_agua, 1);
      expect(cart.totalWith(1000), 2200);
    });

    test('toRpcItems só envia id e quantidade (nunca preços)', () {
      final cart = const Cart().withQuantity(_agua, 2).withQuantity(_gelo, 1);
      expect(cart.toRpcItems(), [
        {'product_id': 'p1', 'quantity': 2},
        {'product_id': 'p2', 'quantity': 1},
      ]);
    });

    test('é imutável: withQuantity devolve novo carrinho', () {
      const base = Cart();
      final next = base.withQuantity(_agua, 1);
      expect(base.isEmpty, isTrue);
      expect(next.isEmpty, isFalse);
    });
  });
}
