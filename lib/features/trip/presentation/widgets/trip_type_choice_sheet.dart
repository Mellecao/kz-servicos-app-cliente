import 'package:flutter/material.dart';

class TripTypeChoiceSheet extends StatelessWidget {
  const TripTypeChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('⚡', style: TextStyle(fontSize: 28)),
              title: const Text('Preciso de uma viagem agora'),
              subtitle: const Text('Corrida Flash — motoristas próximos'),
              onTap: () => Navigator.of(context).pop('flash'),
            ),
            const Divider(),
            ListTile(
              leading: const Text('📅', style: TextStyle(fontSize: 24)),
              title: const Text('Quero agendar uma viagem'),
              subtitle: const Text('Escolha data, horário e opções'),
              onTap: () => Navigator.of(context).pop('scheduled'),
            ),
          ],
        ),
      ),
    );
  }
}
