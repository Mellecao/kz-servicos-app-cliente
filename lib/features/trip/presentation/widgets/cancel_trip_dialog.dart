import 'package:flutter/material.dart';

class CancelTripDialog extends StatefulWidget {
  const CancelTripDialog({super.key});

  @override
  State<CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<CancelTripDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar viagem?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'O cancelamento será feito imediatamente. Se quiser, informe o motivo.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('cancel_reason_input'),
            controller: _reasonController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_reasonController.text.trim());
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          child: const Text('Cancelar viagem'),
        ),
      ],
    );
  }
}
