import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/angola_phone.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_orders_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/order_status_badge.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';

/// Detalhe do pedido. Lê o pedido do [ProductOrdersCubit], que se atualiza em
/// tempo real: a linha de estado muda sozinha quando o admin avança o pedido.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProductOrdersCubit>();
    if (cubit.state.byId(widget.orderId) == null) cubit.load();
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelOrderDialog(),
    );
    if (reason == null || !context.mounted) return;
    final ok = await context.read<ProductOrdersCubit>().cancel(
      widget.orderId,
      reason: reason,
    );
    if (!context.mounted) return;
    final cubit = context.read<ProductOrdersCubit>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFB3261E),
          content: Text(
            ok
                ? 'Pedido cancelado.'
                : (cubit.state.actionError ??
                      'Não foi possível cancelar o pedido.'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheetBackground,
      body: Column(
        children: [
          const ProductsHeader(title: 'Detalhe do pedido'),
          Expanded(
            child: BlocBuilder<ProductOrdersCubit, ProductOrdersState>(
              builder: (context, state) {
                final order = state.byId(widget.orderId);
                if (order == null) {
                  if (state.status == ProductOrdersStatus.error) {
                    return ProductsMessageView(
                      icon: Icons.error_outline_rounded,
                      iconColor: const Color(0xFFEF5350),
                      title: 'Erro ao carregar o pedido',
                      subtitle: state.message,
                      actionLabel: 'Tentar novamente',
                      onAction: () => context.read<ProductOrdersCubit>().load(),
                    );
                  }
                  if (state.status == ProductOrdersStatus.loaded) {
                    return const ProductsMessageView(
                      icon: Icons.search_off_rounded,
                      title: 'Pedido não encontrado',
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.highlight),
                  );
                }
                return _Body(
                  order: order,
                  cancelling: state.cancellingId == order.id,
                  onCancel: () => _confirmCancel(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.order,
    required this.cancelling,
    required this.onCancel,
  });

  final ProductOrder order;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _Card(
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              if (order.status == ProductOrderStatus.cancelled) ...[
                const SizedBox(height: 12),
                Text(
                  order.cancelReason == null
                      ? 'Este pedido foi cancelado.'
                      : 'Este pedido foi cancelado. Motivo: ${order.cancelReason}',
                  style: const TextStyle(color: Color(0xFFEF5350)),
                ),
              ] else ...[
                const SizedBox(height: 16),
                OrderStatusTimeline(status: order.status),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Itens',
          child: Column(
            children: [
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}× ${item.productName}',
                          style: const TextStyle(
                            color: AppColors.sheetTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        formatKz(item.lineTotal),
                        style: const TextStyle(
                          color: AppColors.sheetTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 20, color: AppColors.sheetBackground),
              OrderTotals(
                subtotal: order.subtotal,
                deliveryFee: order.deliveryFee,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Entrega e pagamento',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Info(Icons.location_on_outlined, order.deliveryAddress),
              if (order.deliveryReference != null)
                _Info(Icons.flag_outlined, order.deliveryReference!),
              if (order.contactPhone != null)
                _Info(
                  Icons.phone_outlined,
                  displayAngolaPhone(order.contactPhone),
                ),
              _Info(
                Icons.payments_outlined,
                paymentMethodLabel(order.paymentMethod),
              ),
              if (order.notes != null)
                _Info(Icons.notes_rounded, order.notes!),
            ],
          ),
        ),
        if (order.status.canCancel) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              key: const Key('order_cancel'),
              onPressed: cancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF5350),
                side: const BorderSide(color: Color(0xFFEF5350)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: cancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Cancelar pedido'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.sheetTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.sheetTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.sheetTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de cancelamento. É dono do controller do motivo: libertá-lo fora
/// daqui, logo após o `pop`, deixava o `TextField` a usá-lo durante a animação
/// de saída ("TextEditingController was used after being disposed").
/// Devolve o motivo (pode ser vazio) ao confirmar, ou `null` ao manter.
class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog();

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.sheetSurface,
      title: const Text(
        'Cancelar pedido?',
        style: TextStyle(color: AppColors.sheetTextPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Só é possível cancelar enquanto o pedido está pendente.',
            style: TextStyle(color: AppColors.sheetTextSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('cancel_reason'),
            controller: _reason,
            maxLength: 200,
            style: const TextStyle(color: AppColors.sheetTextPrimary),
            decoration: productInputDecoration('Motivo (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Manter pedido',
            style: TextStyle(color: AppColors.sheetTextSecondary),
          ),
        ),
        TextButton(
          key: const Key('cancel_confirm'),
          onPressed: () => Navigator.of(context).pop(_reason.text),
          child: const Text(
            'Cancelar pedido',
            style: TextStyle(color: Color(0xFFEF5350)),
          ),
        ),
      ],
    );
  }
}
