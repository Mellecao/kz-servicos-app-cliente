import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/products/data/models/product.dart';

/// Estado do pedido (`product_order_status`):
/// `pending → confirmed → out_for_delivery → delivered`, ou `cancelled`.
enum ProductOrderStatus {
  pending('pending', 'Pendente', 0),
  confirmed('confirmed', 'Confirmado', 1),
  outForDelivery('out_for_delivery', 'A caminho', 2),
  delivered('delivered', 'Entregue', 3),
  cancelled('cancelled', 'Cancelado', -1);

  const ProductOrderStatus(this.dbValue, this.label, this.step);

  final String dbValue;
  final String label;

  /// Posição na linha de estado (0–3). `-1` para cancelado.
  final int step;

  static ProductOrderStatus fromDb(String? value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => ProductOrderStatus.pending,
  );

  /// O cliente só cancela enquanto o pedido está pendente.
  bool get canCancel => this == ProductOrderStatus.pending;

  bool get isFinal =>
      this == ProductOrderStatus.delivered ||
      this == ProductOrderStatus.cancelled;
}

/// Formas de pagamento aceites nos pedidos de produtos (sem `pix`).
const List<String> kProductPaymentMethods = ['cash', 'debit', 'credit'];

String paymentMethodLabel(String method) => switch (method) {
  'cash' => 'Numerário',
  'debit' => 'Multicaixa / cartão de débito',
  'credit' => 'Cartão de crédito',
  'billing' => 'Faturação',
  _ => method,
};

class ProductOrderItem extends Equatable {
  const ProductOrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory ProductOrderItem.fromJson(Map<String, dynamic> json) =>
      ProductOrderItem(
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        unitPrice: numericToDouble(json['unit_price']),
        quantity: (json['quantity'] as num).toInt(),
        lineTotal: numericToDouble(json['line_total']),
      );

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  @override
  List<Object?> get props => [
    productId,
    productName,
    unitPrice,
    quantity,
    lineTotal,
  ];
}

class ProductOrder extends Equatable {
  const ProductOrder({
    required this.id,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.deliveryReference,
    this.contactPhone,
    this.notes,
    this.cancelReason,
    this.items = const [],
  });

  factory ProductOrder.fromJson(Map<String, dynamic> json) => ProductOrder(
    id: json['id'] as String,
    status: ProductOrderStatus.fromDb(json['status'] as String?),
    deliveryAddress: json['delivery_address'] as String,
    deliveryReference: json['delivery_reference'] as String?,
    contactPhone: json['contact_phone'] as String?,
    notes: json['notes'] as String?,
    paymentMethod: (json['payment_method'] as String?) ?? 'cash',
    subtotal: numericToDouble(json['subtotal']),
    deliveryFee: numericToDouble(json['delivery_fee']),
    total: numericToDouble(json['total']),
    cancelReason: json['cancel_reason'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    items: ((json['product_order_items'] as List?) ?? const [])
        .map((e) => ProductOrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final ProductOrderStatus status;
  final String deliveryAddress;
  final String? deliveryReference;
  final String? contactPhone;
  final String? notes;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? cancelReason;
  final DateTime createdAt;
  final List<ProductOrderItem> items;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [
    id,
    status,
    deliveryAddress,
    deliveryReference,
    contactPhone,
    notes,
    paymentMethod,
    subtotal,
    deliveryFee,
    total,
    cancelReason,
    createdAt,
    items,
  ];
}
