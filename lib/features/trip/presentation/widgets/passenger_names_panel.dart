import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart';

class PassengerName {
  const PassengerName({
    required this.name,
    this.age,
    this.isCurrentClient = false,
  });

  final String name;
  final int? age;
  final bool isCurrentClient;

  bool get isChild => age != null && age! <= 10;
}

class PassengerNamesPanel extends StatefulWidget {
  const PassengerNamesPanel({
    super.key,
    this.title = 'Passageiros',
    required this.currentClientName,
    this.currentClientAge,
    required this.onBack,
    required this.onContinue,
    this.initialPassengers = const [],
  });

  final String title;
  final String currentClientName;
  final int? currentClientAge;
  final VoidCallback onBack;
  final ValueChanged<List<PassengerName>> onContinue;
  final List<PassengerName> initialPassengers;

  @override
  State<PassengerNamesPanel> createState() => _PassengerNamesPanelState();
}

class _PassengerNamesPanelState extends State<PassengerNamesPanel> {
  final List<_PassengerControllers> _rows = [];
  final TextEditingController _clientAge = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final passenger in widget.initialPassengers) {
      if (!passenger.isCurrentClient) {
        _rows.add(_PassengerControllers(passenger.name, passenger.age));
      }
    }
  }

  @override
  void dispose() {
    _clientAge.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  bool get _isValid {
    final clientAge = widget.currentClientAge ?? int.tryParse(_clientAge.text);
    if (clientAge == null || clientAge < 0 || clientAge > 120) return false;
    return _rows.every((row) {
      final age = int.tryParse(row.age.text);
      return row.name.text.trim().isNotEmpty &&
          age != null &&
          age >= 0 &&
          age <= 120;
    });
  }

  void _addPassenger() => setState(() => _rows.add(_PassengerControllers()));

  void _removePassenger(int index) {
    _rows.removeAt(index).dispose();
    setState(() {});
  }

  void _continue() {
    if (!_isValid) return;
    widget.onContinue([
      PassengerName(
        name: widget.currentClientName,
        age: widget.currentClientAge ?? int.parse(_clientAge.text),
        isCurrentClient: true,
      ),
      for (final row in _rows)
        PassengerName(name: row.name.text.trim(), age: int.parse(row.age.text)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: widget.title,
      onBack: widget.onBack,
      confirmLabel: 'Continuar',
      onConfirm: _isValid ? _continue : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cliente atual',
            style: TextStyle(color: AppColors.sheetTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            widget.currentClientName,
            style: const TextStyle(
              color: AppColors.sheetTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.currentClientAge == null) ...[
            const SizedBox(height: 10),
            _field(
              key: const Key('current_client_age'),
              controller: _clientAge,
              label: 'A sua idade',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
          for (var index = 0; index < _rows.length; index++) ...[
            const Divider(height: 28, color: AppColors.sheetTextSecondary),
            _buildRow(index),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _addPassenger,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar passageiro'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _field(
            key: Key('passenger_name_$index'),
            controller: row.name,
            label: 'Nome',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _field(
            key: Key('passenger_age_$index'),
            controller: row.age,
            label: 'Idade',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        IconButton(
          onPressed: () => _removePassenger(index),
          color: AppColors.sheetTextSecondary,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.sheetTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.sheetTextSecondary),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.sheetTextSecondary),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.highlight),
        ),
      ),
    );
  }
}

class _PassengerControllers {
  _PassengerControllers([String name = '', int? age])
    : name = TextEditingController(text: name),
      age = TextEditingController(text: age?.toString() ?? '');

  final TextEditingController name;
  final TextEditingController age;

  void dispose() {
    name.dispose();
    age.dispose();
  }
}
