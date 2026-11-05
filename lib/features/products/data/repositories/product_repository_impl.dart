import 'dart:async';

import 'package:kz_servicos_app/features/products/data/models/product.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Sessão expirada. Inicie sessão novamente.');
    }
    return id;
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return rows.map(Product.fromJson).toList();
  }

  @override
  Future<double?> fetchDeliveryFee() async {
    try {
      final row = await _client
          .from('system_settings')
          .select('value')
          .eq('key', 'product_delivery_fee')
          .maybeSingle();
      final value = row?['value'];
      if (value == null) return null;
      return numericToDouble(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> fetchProfilePhone() async {
    try {
      final row = await _client
          .from('users')
          .select('phone')
          .eq('id', _userId)
          .maybeSingle();
      final phone = row?['phone'] as String?;
      return (phone == null || phone.trim().isEmpty) ? null : phone;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> createOrder({
    required Cart cart,
    required CheckoutForm form,
  }) async {
    final id = await _client.rpc<dynamic>(
      'create_product_order',
      params: {
        'p_items': cart.toRpcItems(),
        'p_delivery_address': form.cleanAddress,
        'p_delivery_reference': form.cleanReference,
        'p_delivery_lat': form.latitude,
        'p_delivery_lng': form.longitude,
        'p_contact_phone': form.phoneE164,
        'p_notes': form.cleanNotes,
        'p_payment_method': form.paymentMethod,
      },
    );
    return id as String;
  }

  @override
  Future<List<ProductOrder>> fetchOrders() async {
    final rows = await _client
        .from('product_orders')
        .select('*, product_order_items(*)')
        .eq('client_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(ProductOrder.fromJson).toList();
  }

  @override
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _client.rpc<dynamic>(
      'cancel_product_order',
      params: {'p_order_id': orderId, 'p_reason': reason},
    );
  }

  @override
  Stream<void> orderChanges() {
    final userId = _userId;
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('product-orders-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'product_orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'client_id',
                value: userId,
              ),
              callback: (_) {
                if (!controller.isClosed) controller.add(null);
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _client.removeChannel(c);
        await controller.close();
      },
    );
    return controller.stream;
  }
}
