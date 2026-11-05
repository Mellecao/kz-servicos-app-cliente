import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/products/data/models/product.dart';

/// Máximo por produto aceite pelo servidor (`quantity <= 99`).
const int kMaxQuantityPerProduct = 99;

class CartLine extends Equatable {
  const CartLine(this.product, this.quantity);

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  @override
  List<Object?> get props => [product, quantity];
}

/// Carrinho imutável. A ordem das linhas é a ordem em que foram adicionadas.
class Cart extends Equatable {
  const Cart([this.lines = const []]);

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  double get subtotal => lines.fold(0, (sum, l) => sum + l.lineTotal);

  double totalWith(double deliveryFee) => subtotal + deliveryFee;

  int quantityOf(Product product) {
    for (final line in lines) {
      if (line.product.id == product.id) return line.quantity;
    }
    return 0;
  }

  /// Devolve um novo carrinho com a quantidade pedida (0 remove a linha).
  Cart withQuantity(Product product, int quantity) {
    final q = quantity.clamp(0, kMaxQuantityPerProduct);
    final others = lines.where((l) => l.product.id != product.id).toList();
    final index = lines.indexWhere((l) => l.product.id == product.id);
    if (q == 0) return Cart(others);
    final updated = CartLine(product, q);
    if (index == -1) return Cart([...lines, updated]);
    return Cart([...lines]..[index] = updated);
  }

  /// Corpo de `p_items` da RPC. Só ids e quantidades: os preços vêm sempre do
  /// catálogo, no servidor.
  List<Map<String, dynamic>> toRpcItems() => [
    for (final l in lines) {'product_id': l.product.id, 'quantity': l.quantity},
  ];

  @override
  List<Object?> get props => [lines];
}
