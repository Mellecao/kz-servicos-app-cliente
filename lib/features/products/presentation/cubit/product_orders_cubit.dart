import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_errors.dart';

enum ProductOrdersStatus { initial, loading, loaded, error }

class ProductOrdersState extends Equatable {
  const ProductOrdersState({
    this.status = ProductOrdersStatus.initial,
    this.orders = const [],
    this.message,
    this.cancellingId,
    this.actionError,
  });

  final ProductOrdersStatus status;
  final List<ProductOrder> orders;
  final String? message;

  /// Pedido a ser cancelado neste momento (para mostrar progresso).
  final String? cancellingId;

  /// Erro da última ação (cancelar), para mostrar num aviso.
  final String? actionError;

  ProductOrdersState copyWith({
    ProductOrdersStatus? status,
    List<ProductOrder>? orders,
    String? message,
    String? cancellingId,
    bool clearCancelling = false,
    String? actionError,
  }) => ProductOrdersState(
    status: status ?? this.status,
    orders: orders ?? this.orders,
    message: message,
    cancellingId: clearCancelling ? null : (cancellingId ?? this.cancellingId),
    actionError: actionError,
  );

  ProductOrder? byId(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    message,
    cancellingId,
    actionError,
  ];
}

/// "Os meus pedidos": lista + estado em tempo real (realtime em
/// `product_orders`) + cancelar enquanto `pending`.
class ProductOrdersCubit extends Cubit<ProductOrdersState> {
  ProductOrdersCubit({required ProductRepository repository})
    : _repository = repository,
      super(const ProductOrdersState());

  final ProductRepository _repository;
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    emit(state.copyWith(status: ProductOrdersStatus.loading));
    try {
      final orders = await _repository.fetchOrders();
      if (isClosed) return;
      emit(state.copyWith(status: ProductOrdersStatus.loaded, orders: orders));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ProductOrdersStatus.error,
          message: friendlyProductError(
            e,
            fallback: 'Não foi possível carregar os seus pedidos.',
          ),
        ),
      );
    }
    _listen();
  }

  /// Reabre a subscrição em cada `load()`: o canal é filtrado pelo utilizador
  /// autenticado e este cubit vive durante toda a sessão da app (a conta pode
  /// mudar).
  void _listen() {
    _changes?.cancel();
    try {
      _changes = _repository.orderChanges().listen((_) => _silentRefresh());
    } catch (_) {
      _changes = null; // sem sessão: sem realtime
    }
  }

  /// Recarrega sem piscar o ecrã; se falhar, mantém o que já está visível.
  Future<void> _silentRefresh() async {
    try {
      final orders = await _repository.fetchOrders();
      if (isClosed) return;
      emit(state.copyWith(status: ProductOrdersStatus.loaded, orders: orders));
    } catch (_) {}
  }

  /// Devolve `true` se cancelou. Em falha, `actionError` fica preenchido.
  Future<bool> cancel(String orderId, {String? reason}) async {
    emit(state.copyWith(cancellingId: orderId));
    try {
      await _repository.cancelOrder(orderId, reason: reason);
      final orders = await _repository.fetchOrders();
      if (isClosed) return true;
      emit(
        state.copyWith(
          status: ProductOrdersStatus.loaded,
          orders: orders,
          clearCancelling: true,
        ),
      );
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            clearCancelling: true,
            actionError: friendlyProductError(
              e,
              fallback: 'Não foi possível cancelar o pedido.',
            ),
          ),
        );
      }
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
