import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/map_route_preview.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

class ScheduledTripWidget extends StatelessWidget {
  final ScheduledTrip trip;
  final VoidCallback? onDetailsTap;
  final bool showMapPreview;

  const ScheduledTripWidget({
    super.key,
    required this.trip,
    this.onDetailsTap,
    this.showMapPreview = false,
  });

  static const _monthAbbreviations = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String _formatDate(DateTime date) {
    final day = date.day;
    final month = _monthAbbreviations[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMapPreview)
            MapRoutePreview(
              originLat: trip.originLat,
              originLng: trip.originLng,
              destinationLat: trip.destinationLat,
              destinationLng: trip.destinationLng,
              height: 120,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: trip.status),
                const SizedBox(height: 14),
                _RouteIndicator(
                  origin: trip.origin,
                  destination: trip.destination,
                ),
                const SizedBox(height: 14),
                _BottomRow(
                  formattedDate: _formatDate(trip.scheduledDatetime),
                  driverName: trip.driverName,
                  onDetailsTap: onDetailsTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, label) = switch (status) {
      'scheduled' => (
        const Color(0xFFE8F5E9),
        const Color(0xFF4CAF50),
        'Agendada',
      ),
      'open' => (
        const Color(0xFFFFF3E0),
        const Color(0xFFFF9800),
        'Pendente',
      ),
      'under_review' => (
        const Color(0xFFFFF3E0),
        const Color(0xFFFF9800),
        'Em análise',
      ),
      'searching_drivers' => (
        const Color(0xFFE3F2FD),
        const Color(0xFF2261FE),
        'Buscando motorista',
      ),
      'awaiting_client_confirmation' || 'awaiting_driver_confirmation' => (
        const Color(0xFFE3F2FD),
        const Color(0xFF2261FE),
        'Aguardando confirmação',
      ),
      'started' => (
        const Color(0xFFE8F5E9),
        const Color(0xFF4CAF50),
        'Em andamento',
      ),
      _ => (
        const Color(0xFFF5F5F5),
        const Color(0xFF9E9E9E),
        status,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'QuasimodoSemiBold',
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}

class _RouteIndicator extends StatelessWidget {
  final String origin;
  final String destination;

  const _RouteIndicator({
    required this.origin,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              CustomPaint(
                size: const Size(1, 28),
                painter: _DashedLinePainter(color: AppColors.textPrimary),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.highlight,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                origin,
                style: const TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                destination,
                style: const TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
    var startY = 0.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}

class _BottomRow extends StatelessWidget {
  final String formattedDate;
  final String? driverName;
  final VoidCallback? onDetailsTap;

  const _BottomRow({
    required this.formattedDate,
    this.driverName,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (driverName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      driverName!,
                      style: TextStyle(
                        fontFamily: 'QuasimodoSemiBold',
                        fontSize: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onDetailsTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Ver detalhes',
            style: TextStyle(
              fontFamily: 'QuasimodoSemiBold',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
