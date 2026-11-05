import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import '../../domain/entities/flash_proposal.dart';
import '../../domain/repositories/flash_trip_repository.dart';

class FlashDriverProfileModal extends StatefulWidget {
  final FlashProposal proposal;
  final FlashTripRepository repository;
  final Future<void> Function() onAccept;
  const FlashDriverProfileModal({
    super.key,
    required this.proposal,
    required this.repository,
    required this.onAccept,
  });

  @override
  State<FlashDriverProfileModal> createState() =>
      _FlashDriverProfileModalState();
}

class _FlashDriverProfileModalState extends State<FlashDriverProfileModal> {
  Map<String, dynamic>? data;
  bool accepting = false;

  @override
  void initState() {
    super.initState();
    widget.repository
        .fetchDriverDetails(widget.proposal.driverProfileId)
        .then((d) {
      if (mounted) setState(() => data = d);
    }).catchError((_) {
      if (mounted) setState(() => data = <String, dynamic>{});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final profilePhotos = (data!['profilePhotos'] as List?) ?? const [];
    final vehiclePhotos = (data!['vehiclePhotos'] as List?) ?? const [];
    final ratingAvg = data!['ratingAvg'];
    final ratingsCount = data!['ratingsCount'] ?? 0;
    final finishedTrips = data!['finishedTrips'] ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proposal.driverName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const Icon(Icons.star, color: AppColors.highlight),
            Text(' ${ratingAvg is num ? ratingAvg.toStringAsFixed(1) : '—'}'
                ' ($ratingsCount avaliações)'),
            const Spacer(),
            Text('$finishedTrips viagens'),
          ]),
          const SizedBox(height: 12),
          Text('Veículo: ${widget.proposal.vehicleLabel}'),
          _photoGrid('Fotos do motorista', profilePhotos),
          _photoGrid('Fotos do veículo', vehiclePhotos),
          const SizedBox(height: 24),
          Center(
            child: Text(
              formatKz(widget.proposal.offeredPrice),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: accepting
                ? null
                : () async {
                    setState(() => accepting = true);
                    final nav = Navigator.of(context);
                    try {
                      await widget.onAccept();
                      if (mounted) nav.pop();
                    } catch (_) {
                      if (mounted) setState(() => accepting = false);
                    }
                  },
            child: accepting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Aceitar proposta'),
          ),
        ],
      ),
    );
  }

  Widget _photoGrid(String title, List photos) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: photos
              .map<Widget>((u) => Image.network(u as String, fit: BoxFit.cover))
              .toList(),
        ),
      ],
    );
  }
}
