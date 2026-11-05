import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/products/data/models/product.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_errors.dart';

enum ProductsStatus { initial, loading, loaded, error }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.cart = const Cart(),
    this.deliveryFee,
    this.message,
  });

  final ProductsStatus status;
  final List<Product> products;
  final Cart cart;

  /// `null` enquanto desconhecida (o servidor aplica a taxa certa ao criar o
  /// pedido, e o ecrã de sucesso mostra o total real).
  final double? deliveryFee;
  final String? message;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    Cart? cart,
    double? deliveryFee,
    String? message,
  }) => ProductsState(
    status: status ?? this.status,
    products: products ?? this.products,
    cart: cart ?? this.cart,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    message: message,
  );

  @override
  List<Object?> get props => [status, products, cart, deliveryFee, message];
}

/// Catálogo + carrinho. O carrinho vive aqui e sobrevive a recargas.
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({required ProductRepository repository})
    : _repository = repository,
      super(const ProductsState());

  final ProductRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ProductsStatus.loading));
    try {
      final products = await _repository.fetchProducts();
      final fee = await _repository.fetchDeliveryFee();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductsStatus.loaded,
          products: products,
          deliveryFee: fee,
          cart: _reconcile(state.cart, products),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductsStatus.error,
          message: friendlyProductError(
            e,
            fallback: 'Não foi possível carregar os produtos.',
          ),
        ),
      );
    }
  }

  void setQuantity(Product product, int quantity) =>
      emit(state.copyWith(cart: state.cart.withQuantity(product, quantity)));

  void clearCart() => emit(state.copyWith(cart: const Cart()));

  /// Depois de recarregar, remove do carrinho produtos que já não existem no
  /// catálogo ativo e atualiza os preços mostrados.
  Cart _reconcile(Cart cart, List<Product> products) {
    var next = const Cart();
    for (final line in cart.lines) {
      final fresh = products.where((p) => p.id == line.product.id);
      if (fresh.isNotEmpty) {
        next = next.withQuantity(fresh.first, line.quantity);
      }
    }
    return next;
  }
}
