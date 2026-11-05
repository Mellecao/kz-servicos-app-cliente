import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/products_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_card.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';

/// Catálogo de produtos com entrega ao domicílio.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheetBackground,
      body: Column(
        children: [
          ProductsHeader(
            title: 'Produtos',
            trailing: TextButton.icon(
              key: const Key('products_my_orders'),
              onPressed: () => context.push('/products/orders'),
              icon: const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.highlight,
              ),
              label: const Text(
                'Os meus pedidos',
                style: TextStyle(color: AppColors.highlight),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                switch (state.status) {
                  case ProductsStatus.initial:
                  case ProductsStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.highlight,
                      ),
                    );
                  case ProductsStatus.error:
                    return ProductsMessageView(
                      icon: Icons.error_outline_rounded,
                      iconColor: const Color(0xFFEF5350),
                      title: 'Erro ao carregar os produtos',
                      subtitle: state.message,
                      actionLabel: 'Tentar novamente',
                      onAction: () => context.read<ProductsCubit>().load(),
                    );
                  case ProductsStatus.loaded:
                    if (state.products.isEmpty) {
                      return ProductsMessageView(
                        icon: Icons.inventory_2_outlined,
                        title: 'Sem produtos disponíveis',
                        subtitle: 'Volte a verificar dentro de momentos.',
                        actionLabel: 'Atualizar',
                        onAction: () => context.read<ProductsCubit>().load(),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.highlight,
                      onRefresh: () => context.read<ProductsCubit>().load(),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          state.cart.isEmpty ? 24 : 110,
                        ),
                        itemCount: state.products.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          if (i == 0) return const _Intro();
                          final product = state.products[i - 1];
                          return ProductCard(
                            product: product,
                            quantity: state.cart.quantityOf(product),
                            onQuantityChanged: (q) => context
                                .read<ProductsCubit>()
                                .setQuantity(product, q),
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),
          BlocBuilder<ProductsCubit, ProductsState>(
            buildWhen: (a, b) => a.cart != b.cart,
            builder: (context, state) {
              if (state.cart.isEmpty) return const SizedBox.shrink();
              return _CartBar(
                itemCount: state.cart.itemCount,
                subtotal: state.cart.subtotal,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        'Água, gelo e gás entregues em casa, em Luanda.',
        style: TextStyle(color: AppColors.sheetTextSecondary, fontSize: 14),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.itemCount, required this.subtotal});

  final int itemCount;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Material(
          color: AppColors.highlight,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const Key('products_cart_bar'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/products/cart'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart_rounded,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      itemCount == 1
                          ? 'Ver carrinho · 1 item'
                          : 'Ver carrinho · $itemCount itens',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    formatKz(subtotal),
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
