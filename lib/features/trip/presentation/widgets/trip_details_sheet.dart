import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/map_route_preview.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

class TripDetailsSheet extends StatelessWidget {
  const TripDetailsSheet({
    super.key,
    required this.trip,
    this.onCancel,
    this.onChat,
  });

  final ScheduledTrip trip;
  final VoidCallback? onCancel;
  final VoidCallback? onChat;

  static void show(
    BuildContext context,
    ScheduledTrip trip, {
    VoidCallback? onCancel,
    VoidCallback? onChat,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripDetailsSheet(
        trip: trip,
        onCancel: onCancel,
        onChat: onChat,
      ),
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
          if (onCancel != null || onChat != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  if (onChat != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onChat!();
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (onChat != null && onCancel != null) const SizedBox(width: 12),
                  if (onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancelar viagem?'),
                              content: const Text(
                                'Tem certeza que deseja cancelar esta viagem agendada?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Não'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Sim, cancelar'),
                                ),
                              ],
                            ),
                          ).then((confirmed) {
                            if (confirmed == true) {
                              Navigator.of(context).pop();
                              onCancel!();
                            }
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                ],
              ),
            ),
          ],
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 16,
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
