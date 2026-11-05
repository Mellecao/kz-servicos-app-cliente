import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/support_contact.dart';
import '../../domain/entities/quotation_availability.dart';

class ScheduledModeChoiceSheet extends StatelessWidget {
  const ScheduledModeChoiceSheet({super.key, required this.availability});

  final QuotationAvailability availability;

  Future<void> _openSupport() async {
    final uri = Uri.parse('https://wa.me/$supportWhatsappE164');
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
                    ? 'A nossa equipa procura o melhor motorista e preço para si'
                    : 'Disponível das 07h às 20h',
              ),
              onTap: quotationAvailable
                  ? () => Navigator.of(context).pop('scheduled_quote')
                  : null,
            ),
            const Divider(),
            ListTile(
              leading: const Text('👤', style: TextStyle(fontSize: 28)),
              title: const Text('Escolha o seu motorista'),
              subtitle: const Text('Selecione um motorista aprovado da sua confiança'),
              onTap: () => Navigator.of(context).pop('scheduled_choose_driver'),
            ),
            const SizedBox(height: 12),
            _SupportButton(
              highlighted: !quotationAvailable,
              onPressed: _openSupport,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.highlighted, required this.onPressed});

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
          label: const Text('Falar com o suporte'),
        ),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Text('💬'),
      label: const Text('Falar com o suporte'),
    );
  }
}
