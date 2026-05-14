import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/map_route_preview.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

class TripDetailsSheet extends StatelessWidget {
  const TripDetailsSheet({super.key, required this.trip});

  final ScheduledTrip trip;

  static void show(BuildContext context, ScheduledTrip trip) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripDetailsSheet(trip: trip),
    );
  }

  static const _monthAbbr = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String _formatDate(DateTime d) {
    final day = d.day;
    final month = _monthAbbr[d.month - 1];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day $month ${d.year} • $hour:$minute';
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

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Detalhes da Viagem',
            style: TextStyle(
              fontFamily: 'OutfitBlack',
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MapRoutePreview(
              originLat: trip.originLat,
              originLng: trip.originLng,
              destinationLat: trip.destinationLat,
              destinationLng: trip.destinationLng,
              height: 150,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: 'QuasimodoSemiBold',
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.circle,
                    iconColor: AppColors.secondary,
                    iconSize: 8,
                    label: trip.origin,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.circle,
                    iconColor: AppColors.highlight,
                    iconSize: 8,
                    label: trip.destination,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFE0E0E0)),
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.textPrimary.withValues(alpha: 0.6),
                    label: _formatDate(trip.scheduledDatetime),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.people_rounded,
                    iconColor: AppColors.textPrimary.withValues(alpha: 0.6),
                    label:
                        '${trip.passengerCount} passageiro${trip.passengerCount > 1 ? 's' : ''}',
                  ),
                  if (trip.driverName != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.person_rounded,
                      iconColor:
                          AppColors.textPrimary.withValues(alpha: 0.6),
                      label: trip.driverName!,
                    ),
                  ],
                  if (trip.observations != null &&
                      trip.observations!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      iconColor:
                          AppColors.textPrimary.withValues(alpha: 0.6),
                      label: trip.observations!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 24,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.iconColor,
    this.iconSize = 14,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'QuasimodoSemiBold',
              fontSize: 13,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
