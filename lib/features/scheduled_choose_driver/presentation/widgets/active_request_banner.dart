import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class ActiveRequestBanner extends StatelessWidget {
  const ActiveRequestBanner({
    super.key,
    required this.driverName,
    required this.tripId,
  });

  final String driverName;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.highlightSoft,
      child: InkWell(
        onTap: () => context.go('/scheduled-choose-driver/awaiting/$tripId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A aguardar resposta de $driverName',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
