import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_orders_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/order_status_badge.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';

/// "Os meus pedidos": lista com estado em tempo real.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductOrdersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheetBackground,
      body: Column(
        children: [
          const ProductsHeader(title: 'Os meus pedidos'),
          Expanded(
            child: BlocBuilder<ProductOrdersCubit, ProductOrdersState>(
              builder: (context, state) {
                switch (state.status) {
                  case ProductOrdersStatus.initial:
                  case ProductOrdersStatus.loading:
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.highlight,
                      ),
                    );
                  case ProductOrdersStatus.error:
                    return ProductsMessageView(
                      icon: Icons.error_outline_rounded,
                      iconColor: const Color(0xFFEF5350),
                      title: 'Erro ao carregar os pedidos',
                      subtitle: state.message,
                      actionLabel: 'Tentar novamente',
                      onAction: () => context.read<ProductOrdersCubit>().load(),
                    );
                  case ProductOrdersStatus.loaded:
                    if (state.orders.isEmpty) {
                      return ProductsMessageView(
                        icon: Icons.receipt_long_outlined,
                        title: 'Ainda não fez nenhum pedido',
                        subtitle: 'Os seus pedidos de produtos aparecem aqui.',
                        actionLabel: 'Ver produtos',
                        onAction: () => Navigator.of(context).maybePop(),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.highlight,
                      onRefresh: () => context.read<ProductOrdersCubit>().load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        itemCount: state.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _OrderTile(order: state.orders[i]),
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final ProductOrder order;

  @override
  Widget build(BuildContext context) {
    final names = order.items.map((i) => '${i.quantity}× ${i.productName}');
    return Material(
      color: AppColors.sheetSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('order_tile_${order.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/products/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatOrderDate(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.sheetTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                names.isEmpty ? 'Pedido de produtos' : names.join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.sheetTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.sheetTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatKz(order.total),
                    style: const TextStyle(
                      color: AppColors.highlight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
