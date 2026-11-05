import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/products_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/quantity_stepper.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheetBackground,
      body: Column(
        children: [
          const ProductsHeader(title: 'Carrinho'),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                final cart = state.cart;
                if (cart.isEmpty) {
                  return ProductsMessageView(
                    icon: Icons.shopping_cart_outlined,
                    title: 'O carrinho está vazio',
                    subtitle: 'Adicione produtos para fazer um pedido.',
                    actionLabel: 'Ver produtos',
                    onAction: () => Navigator.of(context).maybePop(),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: cart.lines.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final line = cart.lines[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.sheetSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  productIcon(line.product.slug),
                                  color: AppColors.highlight,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.product.name,
                                        style: const TextStyle(
                                          color: AppColors.sheetTextPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatKz(line.lineTotal),
                                        style: const TextStyle(
                                          color: AppColors.highlight,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                QuantityStepper(
                                  quantity: line.quantity,
                                  onChanged: (q) => context
                                      .read<ProductsCubit>()
                                      .setQuantity(line.product, q),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        decoration: const BoxDecoration(
                          color: AppColors.sheetSurface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OrderTotals(
                              subtotal: cart.subtotal,
                              deliveryFee: state.deliveryFee,
                            ),
                            const SizedBox(height: 14),
                            PrimaryActionButton(
                              label: 'Continuar',
                              onPressed: () => context.push('/products/checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
