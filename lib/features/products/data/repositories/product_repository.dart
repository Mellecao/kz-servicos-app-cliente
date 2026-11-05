import 'package:kz_servicos_app/features/products/data/models/product.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';

abstract class ProductRepository {
  /// Catálogo ativo, por ordem de `sort_order`.
  Future<List<Product>> fetchProducts();

  /// Taxa de entrega (`system_settings.product_delivery_fee`). `null` quando o
  /// valor não está legível para o cliente (RLS) ou falha a leitura.
  Future<double?> fetchDeliveryFee();

  /// Telemóvel do perfil, para pré-preencher o checkout. `null` se não houver.
  Future<String?> fetchProfilePhone();

  /// Cria o pedido pela RPC `create_product_order` e devolve o id.
  Future<String> createOrder({required Cart cart, required CheckoutForm form});

  /// Pedidos do cliente autenticado (RLS), do mais recente para o mais antigo.
  Future<List<ProductOrder>> fetchOrders();

  /// Cancela pela RPC `cancel_product_order` (só pedidos pendentes).
  Future<void> cancelOrder(String orderId, {String? reason});

  /// Emite um evento sempre que um pedido do cliente muda (realtime em
  /// `product_orders`). Cancelar a subscrição fecha o canal.
  Stream<void> orderChanges();
}
