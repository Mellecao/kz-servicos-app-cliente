import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

import '../../domain/entities/available_driver.dart';

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.driver,
    required this.onRequest,
    this.onTap,
    this.isLoading = false,
  });

  final AvailableDriver driver;
  final ValueChanged<String> onRequest;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final initial = driver.fullName.isEmpty
        ? '?'
        : driver.fullName[0].toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0xFF2B2B2B),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: driver.avatarUrl != null
                    ? NetworkImage(driver.avatarUrl!)
                    : null,
                child: driver.avatarUrl == null ? Text(initial) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.highlight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          driver.averageRating == null
                              ? 'Sem avaliações'
                              : '${driver.averageRating!.toStringAsFixed(1)} (${driver.totalRatings})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (driver.vehicle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${driver.vehicle!.brand} ${driver.vehicle!.model} · ${driver.vehicle!.licensePlate}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () => onRequest(driver.driverProfileId),
                child: const Text('Solicitar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
