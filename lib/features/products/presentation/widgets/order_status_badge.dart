import 'package:flutter/material.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final ProductOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(orderStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de estado: Pendente → Confirmado → A caminho → Entregue.
/// Para pedidos cancelados mostra um aviso em vez da linha.
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final ProductOrderStatus status;

  static const _steps = [
    ProductOrderStatus.pending,
    ProductOrderStatus.confirmed,
    ProductOrderStatus.outForDelivery,
    ProductOrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == ProductOrderStatus.cancelled) {
      return const SizedBox.shrink();
    }
    const done = Color(0xFF66BB6A);
    const idle = Color(0xFF4A4A4A);
    return Row(
      key: const Key('order_timeline'),
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Icon(
                  i <= status.step
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: i < status.step
                      ? done
                      : (i == status.step
                            ? orderStatusColor(status)
                            : idle),
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  _steps[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == status.step
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: i <= status.step
                        ? Colors.white
                        : const Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
