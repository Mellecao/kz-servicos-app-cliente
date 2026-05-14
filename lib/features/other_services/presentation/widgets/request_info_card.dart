import 'package:flutter/material.dart';

import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_status_badge.dart';

class RequestInfoCard extends StatelessWidget {
  final ServiceRequest request;
  final ServiceRequestStatus currentStatus;

  const RequestInfoCard({
    super.key,
    required this.request,
    required this.currentStatus,
  });

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = ServiceCategory.colorForSlug(request.categoryId);
    final categoryIcon = ServiceCategory.iconForSlug(request.categoryId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, size: 20, color: categoryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  request.categoryName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RequestStatusBadge(status: currentStatus),
            ],
          ),
          const Divider(height: 24),
          Text(
            request.problem,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.details,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey,
            ),
          ),
          if (request.address != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.address!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                request.urgency == UrgencyType.now
                    ? Icons.bolt
                    : Icons.calendar_today,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                request.urgency == UrgencyType.now
                    ? 'Urgente'
                    : 'Agendado - ${_formatDate(request.scheduledDate!)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
