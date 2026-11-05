import 'package:flutter/material.dart';

import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

/// Progresso do serviço: Atribuído → Em curso → Concluído.
class ServiceProgressTimeline extends StatelessWidget {
  const ServiceProgressTimeline({super.key, required this.status});

  final ServiceRequestStatus status;

  static const _steps = ['Atribuído', 'Em curso', 'Concluído'];

  @override
  Widget build(BuildContext context) {
    final current = status.progressStep;
    const done = Color(0xFF2E7D32);
    return Container(
      key: const Key('service_timeline'),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++)
            Expanded(
              child: Column(
                children: [
                  Icon(
                    i <= current
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 28,
                    color: i < current || (i == current && status == ServiceRequestStatus.finished)
                        ? done
                        : (i == current ? AppColors.highlight : Colors.grey.shade400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                      color: i <= current ? AppColors.textPrimary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
