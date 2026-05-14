import 'package:flutter/material.dart';

import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_status_badge.dart';

class RequestListTile extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onTap;

  const RequestListTile({
    super.key,
    required this.request,
    required this.onTap,
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

    final formattedDate = _formatDate(request.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.categoryName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamilyTitle,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.problem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  RequestStatusBadge(status: request.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
