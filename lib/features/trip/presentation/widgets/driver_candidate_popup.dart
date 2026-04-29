import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/driver_candidate.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_with_candidates.dart';

/// Modal dialog that lets the client confirm one of the drivers who applied
/// to a trip. Returns the selected [DriverCandidate] when the user confirms,
/// or `null` if dismissed via the close button or barrier.
class DriverCandidatePopup extends StatefulWidget {
  const DriverCandidatePopup({super.key, required this.item});

  final TripWithCandidates item;

  static Future<DriverCandidate?> show(
    BuildContext context,
    TripWithCandidates item,
  ) {
    return showDialog<DriverCandidate>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriverCandidatePopup(item: item),
    );
  }

  @override
  State<DriverCandidatePopup> createState() => _DriverCandidatePopupState();
}

class _DriverCandidatePopupState extends State<DriverCandidatePopup> {
  String? _acceptingCandidateId;

  static const _monthAbbr = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  String _formatDate(DateTime d) {
    final day = d.day;
    final month = _monthAbbr[d.month - 1];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day $month • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.item.trip;
    final candidates = widget.item.candidates;
    final mediaQuery = MediaQuery.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTripSummary(trip.origin, trip.destination,
                        _formatDate(trip.scheduledDatetime),
                        trip.passengerCount),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Motoristas disponíveis (${candidates.length})',
                        style: const TextStyle(
                          fontFamily: 'QuasimodoSemiBold',
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    for (final candidate in candidates) ...[
                      _CandidateTile(
                        candidate: candidate,
                        isAccepting: _acceptingCandidateId == candidate.candidateId,
                        isAnyAccepting: _acceptingCandidateId != null,
                        onAccept: () => _onAccept(candidate),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Motorista encontrado!',
              style: TextStyle(
                fontFamily: 'OutfitBlack',
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: _acceptingCandidateId != null
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF8E8E8E),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary(
      String origin, String destination, String date, int passengerCount) {
    final mutedColor = AppColors.textPrimary.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                date,
                style: TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.people_rounded, size: 14, color: mutedColor),
              const SizedBox(width: 4),
              Text(
                '$passengerCount',
                style: TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AddressLine(
            color: AppColors.secondary,
            label: 'Origem',
            value: origin,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 6),
          _AddressLine(
            color: AppColors.highlight,
            label: 'Destino',
            value: destination,
            mutedColor: mutedColor,
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(DriverCandidate candidate) async {
    if (_acceptingCandidateId != null) return;
    setState(() => _acceptingCandidateId = candidate.candidateId);
    if (!mounted) return;
    Navigator.of(context).pop(candidate);
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({
    required this.color,
    required this.label,
    required this.value,
    required this.mutedColor,
  });

  final Color color;
  final String label;
  final String value;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 10,
                  color: mutedColor,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.isAccepting,
    required this.isAnyAccepting,
    required this.onAccept,
  });

  final DriverCandidate candidate;
  final bool isAccepting;
  final bool isAnyAccepting;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        candidate.avatarUrl != null && candidate.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.background,
            backgroundImage:
                hasAvatar ? NetworkImage(candidate.avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    candidate.initials,
                    style: const TextStyle(
                      fontFamily: 'OutfitBlack',
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  candidate.driverName,
                  style: const TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (candidate.vehicleSummary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    candidate.vehicleSummary!,
                    style: TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (candidate.vehiclePlate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${candidate.vehiclePlate}'
                    '${candidate.vehicleColor != null ? ' • ${candidate.vehicleColor}' : ''}',
                    style: TextStyle(
                      fontFamily: 'QuasimodoSemiBold',
                      fontSize: 11,
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: isAnyAccepting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.highlight.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isAccepting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Aceitar',
                      style: TextStyle(
                        fontFamily: 'QuasimodoSemiBold',
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
