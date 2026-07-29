import 'package:flutter/material.dart';
import '../../domain/entities/trip_execution_stage.dart';

class LiveTripBottomSheet extends StatelessWidget {
  const LiveTripBottomSheet({
    super.key,
    required this.driverName,
    required this.driverPhotoUrl,
    required this.vehicleLabel,
    required this.etaMinutes,
    required this.distanceMeters,
    required this.stage,
    required this.onCall,
    required this.onChat,
    this.onCancel,
  });

  final String driverName;
  final String? driverPhotoUrl;
  final String vehicleLabel;
  final int? etaMinutes;
  final double? distanceMeters;
  final TripExecutionStage stage;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stageBadge(),
              const SizedBox(height: 12),
              Row(children: [
                _avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(vehicleLabel, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
                _iconAction(Icons.chat_bubble_outline, onChat),
                const SizedBox(width: 8),
                _iconAction(Icons.phone, onCall),
              ]),
              const Divider(height: 24),
              Row(children: [
                Expanded(child: _metric('Chegada', etaMinutes == null ? '—' : '$etaMinutes min')),
                Expanded(child: _metric('Distância', _formatDistance(distanceMeters))),
              ]),
              if (onCancel != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(stage.label,
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
      );

  Widget _avatar() {
    final initial = driverName.isNotEmpty ? driverName.characters.first.toUpperCase() : '?';
    return CircleAvatar(
      radius: 24,
      backgroundImage: driverPhotoUrl != null ? NetworkImage(driverPhotoUrl!) : null,
      child: driverPhotoUrl == null ? Text(initial, style: const TextStyle(fontSize: 20)) : null,
    );
  }

  Widget _iconAction(IconData icon, VoidCallback onTap) => Ink(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: IconButton(icon: Icon(icon), onPressed: onTap, splashRadius: 22),
      );

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        ],
      );

  static String _formatDistance(double? meters) {
    if (meters == null) return '—';
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    // pt-BR uses comma as decimal separator; single decimal digit
    final rounded = (km * 10).round() / 10;
    return '${rounded.toString().replaceAll('.', ',')} km';
  }
}
