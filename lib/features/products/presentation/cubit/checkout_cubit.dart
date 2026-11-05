import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_errors.dart';

enum CheckoutStatus { idle, submitting, success, failure }

class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.message,
  });

  final CheckoutStatus status;
  final String? orderId;
  final String? message;

  @override
  List<Object?> get props => [status, orderId, message];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({required ProductRepository repository})
    : _repository = repository,
      super(const CheckoutState());

  final ProductRepository _repository;

  Future<void> submit(Cart cart, CheckoutForm form) async {
    if (state.status == CheckoutStatus.submitting) return;
    if (cart.isEmpty) {
      emit(
        const CheckoutState(
          status: CheckoutStatus.failure,
          message: 'O carrinho está vazio.',
        ),
      );
      return;
    }
    if (!form.isValid) {
      emit(
        const CheckoutState(
          status: CheckoutStatus.failure,
          message: 'Verifique a morada e o telemóvel.',
        ),
      );
      return;
    }
    emit(const CheckoutState(status: CheckoutStatus.submitting));
    try {
      final id = await _repository.createOrder(cart: cart, form: form);
      if (isClosed) return;
      emit(CheckoutState(status: CheckoutStatus.success, orderId: id));
    } catch (e) {
      if (isClosed) return;
      emit(
        CheckoutState(
          status: CheckoutStatus.failure,
          message: friendlyProductError(
            e,
            fallback: 'Não foi possível enviar o pedido. Tente novamente.',
          ),
        ),
      );
    }
  }
}
