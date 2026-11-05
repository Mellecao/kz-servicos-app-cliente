import 'package:flutter/material.dart';

import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

class RequestStatusBadge extends StatelessWidget {
  final ServiceRequestStatus status;

  const RequestStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = styleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cor e ícone por estado (partilhado com o ecrã de detalhe).
  static ({Color color, IconData icon}) styleFor(ServiceRequestStatus status) {
    return switch (status) {
      ServiceRequestStatus.open => (
        color: const Color(0xFF78909C),
        icon: Icons.send_rounded,
      ),
      ServiceRequestStatus.underReview => (
        color: const Color(0xFF78909C),
        icon: Icons.fact_check_outlined,
      ),
      ServiceRequestStatus.reviewRejected => (
        color: const Color(0xFFD32F2F),
        icon: Icons.block_rounded,
      ),
      ServiceRequestStatus.searchingProvider => (
        color: const Color(0xFFEF6C00),
        icon: Icons.search,
      ),
      ServiceRequestStatus.awaitingClientConfirmation => (
        color: const Color(0xFF1565C0),
        icon: Icons.touch_app_outlined,
      ),
      ServiceRequestStatus.awaitingProviderConfirmation => (
        color: const Color(0xFFF9A825),
        icon: Icons.hourglass_top,
      ),
      ServiceRequestStatus.assigned => (
        color: const Color(0xFF2E7D32),
        icon: Icons.check_circle,
      ),
      ServiceRequestStatus.inProgress => (
        color: const Color(0xFF1E88E5),
        icon: Icons.build_circle_outlined,
      ),
      ServiceRequestStatus.finished => (
        color: const Color(0xFF2E7D32),
        icon: Icons.task_alt_rounded,
      ),
      ServiceRequestStatus.cancelled => (
        color: const Color(0xFFD32F2F),
        icon: Icons.cancel_outlined,
      ),
    };
  }
}
