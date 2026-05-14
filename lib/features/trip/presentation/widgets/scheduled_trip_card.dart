import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

class ScheduledTripCard extends StatelessWidget {
  const ScheduledTripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onPrevTap,
    this.onNextTap,
    this.currentIndex = 0,
    this.totalCount = 1,
  });

  final ScheduledTrip trip;
  final VoidCallback? onTap;
  final VoidCallback? onPrevTap;
  final VoidCallback? onNextTap;
  final int currentIndex;
  final int totalCount;

  static const _monthAbbr = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String get _formattedDate {
    final d = trip.scheduledDatetime;
    final day = d.day;
    final month = _monthAbbr[d.month - 1];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day $month • $hour:$minute';
  }

  String get _statusLabel => switch (trip.status) {
        'scheduled' => 'Agendada',
        'open' => 'Pendente',
        'under_review' => 'Em análise',
        'searching_drivers' => 'Buscando motorista',
        'awaiting_client_confirmation' ||
        'awaiting_driver_confirmation' =>
          'Aguardando confirmação',
        'started' => 'Em andamento',
        _ => trip.status,
      };

  (Color bg, Color text) get _statusColors => switch (trip.status) {
        'scheduled' || 'started' => (
          const Color(0xFFE8F5E9),
          const Color(0xFF4CAF50),
        ),
        'open' || 'under_review' => (
          const Color(0xFFFFF3E0),
          const Color(0xFFFF9800),
        ),
        _ => (
          const Color(0xFFE3F2FD),
          const Color(0xFF2261FE),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _statusColors;
    final label = _statusLabel;
    final mutedColor = AppColors.textPrimary.withValues(alpha: 0.5);
    final hasMultiple = totalCount > 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header: status badge + date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 11,
                      color: textColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule_rounded, size: 13, color: mutedColor),
                const SizedBox(width: 4),
                Text(
                  _formattedDate,
                  style: TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 11,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Route row: indicator + addresses
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildRouteIndicator(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAddressBlock(
                        label: 'Origem',
                        address: trip.origin,
                        labelColor: mutedColor,
                      ),
                      const SizedBox(height: 10),
                      _buildAddressBlock(
                        label: 'Destino',
                        address: trip.destination,
                        labelColor: mutedColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Navigation row (always rendered to keep height stable)
            _buildNavRow(mutedColor, hasMultiple),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow(Color mutedColor, bool hasMultiple) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Prev chevron
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasMultiple ? onPrevTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 24,
              color: hasMultiple ? mutedColor : Colors.transparent,
            ),
          ),
        ),
        // Page dots
        if (hasMultiple)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalCount, (i) {
              final isActive = i == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.highlight
                      : AppColors.textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          )
        else
          const SizedBox.shrink(),
        // Next chevron
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasMultiple ? onNextTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: hasMultiple ? mutedColor : Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteIndicator() {
    return SizedBox(
      width: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 2,
            height: 24,
            color: AppColors.textPrimary.withValues(alpha: 0.18),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.highlight,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBlock({
    required String label,
    required String address,
    required Color labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'QuasimodoSemiBold',
            fontSize: 10,
            color: labelColor,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          address,
          style: const TextStyle(
            fontFamily: 'QuasimodoSemiBold',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
