import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';

Map<String, dynamic> _json({String status = 'pending'}) => {
  'id': 'o1',
  'status': status,
  'delivery_address': 'Talatona, Luanda',
  'delivery_reference': 'Perto da bomba',
  'contact_phone': '+244923000001',
  'notes': null,
  'payment_method': 'cash',
  'subtotal': 3600,
  'delivery_fee': '1000.00',
  'total': 4600,
  'cancel_reason': null,
  'created_at': '2026-11-05T10:30:00+00:00',
  'product_order_items': [
    {
      'id': 'i1',
      'product_id': 'p1',
      'product_name': 'Água 20 L',
      'unit_price': 1200,
      'quantity': 3,
      'line_total': 3600,
    },
  ],
};

void main() {
  group('ProductOrderStatus', () {
    test('lê o valor do banco e tem rótulos pt-AO', () {
      expect(ProductOrderStatus.fromDb('pending').label, 'Pendente');
      expect(ProductOrderStatus.fromDb('confirmed').label, 'Confirmado');
      expect(
        ProductOrderStatus.fromDb('out_for_delivery').label,
        'A caminho',
      );
      expect(ProductOrderStatus.fromDb('delivered').label, 'Entregue');
      expect(ProductOrderStatus.fromDb('cancelled').label, 'Cancelado');
    });

    test('valor desconhecido cai em pendente', () {
      expect(ProductOrderStatus.fromDb('xpto'), ProductOrderStatus.pending);
    });

    test('só pendente pode ser cancelado; cancelado/entregue são finais', () {
      expect(ProductOrderStatus.pending.canCancel, isTrue);
      expect(ProductOrderStatus.confirmed.canCancel, isFalse);
      expect(ProductOrderStatus.outForDelivery.canCancel, isFalse);
      expect(ProductOrderStatus.delivered.isFinal, isTrue);
      expect(ProductOrderStatus.cancelled.isFinal, isTrue);
      expect(ProductOrderStatus.confirmed.isFinal, isFalse);
    });

    test('etapa da linha de estado', () {
      expect(ProductOrderStatus.pending.step, 0);
      expect(ProductOrderStatus.confirmed.step, 1);
      expect(ProductOrderStatus.outForDelivery.step, 2);
      expect(ProductOrderStatus.delivered.step, 3);
    });
  });

  group('ProductOrder.fromJson', () {
    test('lê pedido com itens e valores', () {
      final o = ProductOrder.fromJson(_json());
      expect(o.id, 'o1');
      expect(o.status, ProductOrderStatus.pending);
      expect(o.deliveryAddress, 'Talatona, Luanda');
      expect(o.deliveryReference, 'Perto da bomba');
      expect(o.paymentMethod, 'cash');
      expect(o.subtotal, 3600);
      expect(o.deliveryFee, 1000);
      expect(o.total, 4600);
      expect(o.items.single.productName, 'Água 20 L');
      expect(o.items.single.quantity, 3);
      expect(o.items.single.lineTotal, 3600);
      expect(o.createdAt.toUtc().hour, 10);
    });

    test('pedido sem itens carregados fica com lista vazia', () {
      final j = _json()..remove('product_order_items');
      expect(ProductOrder.fromJson(j).items, isEmpty);
    });
  });

  group('rótulos de pagamento', () {
    test('usa vocabulário de Angola e esconde pix', () {
      expect(paymentMethodLabel('cash'), 'Numerário');
      expect(paymentMethodLabel('debit'), 'Multicaixa / cartão de débito');
      expect(paymentMethodLabel('credit'), 'Cartão de crédito');
      expect(kProductPaymentMethods, ['cash', 'debit', 'credit']);
    });
  });
}
