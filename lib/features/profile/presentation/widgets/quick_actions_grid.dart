import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  final int completedTrips;
  final String completedTripsLabel;
  final int requestedServices;
  final int unreadMessages;
  final VoidCallback? onTripsTap;
  final VoidCallback? onServicesTap;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onPaymentsTap;

  const QuickActionsGrid({
    super.key,
    required this.completedTrips,
    this.completedTripsLabel = 'realizadas',
    required this.requestedServices,
    required this.unreadMessages,
    this.onTripsTap,
    this.onServicesTap,
    this.onMessagesTap,
    this.onPaymentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.local_taxi_rounded,
                  title: 'Viagens',
                  value: '$completedTrips $completedTripsLabel',
                  onTap: onTripsTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.work_rounded,
                  title: 'Serviços',
                  value: '$requestedServices solicitados',
                  onTap: onServicesTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Mensagens',
                  value: '$unreadMessages novas',
                  onTap: onMessagesTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Carteira',
                  value: 'Ver saldo',
                  onTap: onPaymentsTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE8E8E8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.highlight, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
