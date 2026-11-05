import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import '../../domain/entities/flash_proposal.dart';

class FlashProposalCard extends StatelessWidget {
  final FlashProposal proposal;
  final VoidCallback onTap;
  const FlashProposalCard({
    super.key,
    required this.proposal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: proposal.driverPhotoUrl != null
              ? NetworkImage(proposal.driverPhotoUrl!)
              : null,
          child: proposal.driverPhotoUrl == null &&
                  proposal.driverName.isNotEmpty
              ? Text(proposal.driverName.characters.first)
              : null,
        ),
        title: Text(proposal.driverName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(proposal.vehicleLabel),
            Text(proposal.etaMinutes == null
                ? 'ETA indisponível'
                : '${proposal.etaMinutes!.round()} min de distância'),
          ],
        ),
        trailing: Text(
          formatKz(proposal.offeredPrice),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        onTap: onTap,
      ),
    );
  }
}
