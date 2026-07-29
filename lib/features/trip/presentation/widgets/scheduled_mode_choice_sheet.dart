import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/akira_whatsapp.dart';
import '../../domain/entities/quotation_availability.dart';

class ScheduledModeChoiceSheet extends StatelessWidget {
  const ScheduledModeChoiceSheet({super.key, required this.availability});

  final QuotationAvailability availability;

  Future<void> _openAkira() async {
    final uri = Uri.parse('https://wa.me/$akiraWhatsappE164');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final quotationAvailable = availability == QuotationAvailability.available;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: quotationAvailable,
              leading: Text('💰', style: TextStyle(
                fontSize: 28,
                color: quotationAvailable ? null : Colors.grey,
              )),
              title: Text(
                'Cotação',
                style: TextStyle(color: quotationAvailable ? null : Colors.grey),
              ),
              subtitle: Text(
                quotationAvailable
                    ? 'A KZ busca o melhor motorista e preço para você'
                    : 'Disponível das 07h às 20h',
              ),
              onTap: quotationAvailable
                  ? () => Navigator.of(context).pop('scheduled_quote')
                  : null,
            ),
            // TODO Subprojeto 2B: adicionar ListTile "Escolha seu motorista"
            const SizedBox(height: 12),
            _AkiraButton(
              highlighted: !quotationAvailable,
              onPressed: _openAkira,
            ),
          ],
        ),
      ),
    );
  }
}

class _AkiraButton extends StatelessWidget {
  const _AkiraButton({required this.highlighted, required this.onPressed});

  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (highlighted) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Text('💬', style: TextStyle(fontSize: 20)),
          label: const Text('Falar com o Akira'),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Text('💬'),
      label: const Text('Falar com o Akira'),
    );
  }
}
