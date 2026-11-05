import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/angola_phone.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/checkout_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_orders_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/products_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/delivery_address_field.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _reference = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  String _payment = 'cash';
  LatLng? _coordinates;

  @override
  void initState() {
    super.initState();
    _prefillPhone();
  }

  Future<void> _prefillPhone() async {
    final stored = await context.read<ProductRepository>().fetchProfilePhone();
    if (!mounted || _phone.text.isNotEmpty) return;
    _phone.text = editableAngolaPhone(stored);
  }

  @override
  void dispose() {
    _address.dispose();
    _reference.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final form = CheckoutForm(
      address: _address.text,
      reference: _reference.text,
      phone: _phone.text,
      paymentMethod: _payment,
      notes: _notes.text,
      latitude: _coordinates?.latitude,
      longitude: _coordinates?.longitude,
    );
    FocusScope.of(context).unfocus();
    context.read<CheckoutCubit>().submit(
      context.read<ProductsCubit>().state.cart,
      form,
    );
  }

  void _onCheckoutState(BuildContext context, CheckoutState state) {
    if (state.status == CheckoutStatus.success && state.orderId != null) {
      context.read<ProductsCubit>().clearCart();
      context.read<ProductOrdersCubit>().load();
      context.go('/products/success/${state.orderId}');
    } else if (state.status == CheckoutStatus.failure) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFB3261E),
            content: Text(state.message ?? 'Não foi possível enviar o pedido.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: _onCheckoutState,
      builder: (context, checkout) {
        final submitting = checkout.status == CheckoutStatus.submitting;
        final productsState = context.watch<ProductsCubit>().state;
        final cart = productsState.cart;
        return Scaffold(
          backgroundColor: AppColors.sheetBackground,
          body: Column(
            children: [
              const ProductsHeader(title: 'Finalizar pedido'),
              Expanded(
                child:
                    cart.isEmpty &&
                        checkout.status != CheckoutStatus.submitting &&
                        checkout.status != CheckoutStatus.success
                    ? ProductsMessageView(
                        icon: Icons.shopping_cart_outlined,
                        title: 'O carrinho está vazio',
                        actionLabel: 'Ver produtos',
                        onAction: () => context.go('/products'),
                      )
                    : Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            const _SectionTitle('Entrega'),
                            DeliveryAddressField(
                              controller: _address,
                              onCoordinatesChanged: (c) => _coordinates = c,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('checkout_reference'),
                              controller: _reference,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: AppColors.sheetTextPrimary,
                              ),
                              decoration: productInputDecoration(
                                'Ponto de referência (opcional)',
                                hint: 'Ex.: junto à bomba de gasolina',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('checkout_phone'),
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [AngolaPhoneInputFormatter()],
                              validator: validateContactPhone,
                              style: const TextStyle(
                                color: AppColors.sheetTextPrimary,
                              ),
                              decoration: productInputDecoration(
                                'Telemóvel de contacto',
                                hint: '9XX XXX XXX',
                                prefixText: '+244 ',
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _SectionTitle('Pagamento'),
                            for (final method in kProductPaymentMethods)
                              _PaymentOption(
                                method: method,
                                selected: _payment == method,
                                onTap: () => setState(() => _payment = method),
                              ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: const Key('checkout_notes'),
                              controller: _notes,
                              maxLines: 3,
                              maxLength: 300,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(300),
                              ],
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: AppColors.sheetTextPrimary,
                              ),
                              decoration: productInputDecoration(
                                'Notas (opcional)',
                                hint: 'Ex.: portão azul, tocar à campainha',
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _SectionTitle('Resumo'),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.sheetSurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: OrderTotals(
                                subtotal: cart.subtotal,
                                deliveryFee: productsState.deliveryFee,
                              ),
                            ),
                            const SizedBox(height: 20),
                            PrimaryActionButton(
                              label: 'Fazer pedido',
                              loading: submitting,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.sheetTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final String method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (method) {
    'cash' => Icons.payments_rounded,
    'debit' => Icons.credit_card_rounded,
    _ => Icons.credit_score_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('payment_$method'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.highlight.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.highlight
                : AppColors.sheetTextSecondary,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, color: AppColors.sheetTextPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                paymentMethodLabel(method),
                style: const TextStyle(
                  color: AppColors.sheetTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? AppColors.highlight
                  : AppColors.sheetTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
