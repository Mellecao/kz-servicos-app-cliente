import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart';

class LuggageItem {
  const LuggageItem({required this.type, required this.size, this.weightKg});

  final String type;
  final String size;
  final int? weightKg;

  String get summary =>
      [type, size, if (weightKg != null) '$weightKg kg'].join(' • ');
}

class LuggagePanel extends StatefulWidget {
  const LuggagePanel({
    super.key,
    this.title = 'Bagagens',
    required this.onBack,
    required this.onContinue,
    this.initialItems = const [],
  });

  final String title;
  final VoidCallback onBack;
  final ValueChanged<List<LuggageItem>> onContinue;
  final List<LuggageItem> initialItems;

  @override
  State<LuggagePanel> createState() => _LuggagePanelState();
}

class _LuggagePanelState extends State<LuggagePanel> {
  final _type = TextEditingController();
  final _size = TextEditingController();
  final _weight = TextEditingController();
  late final List<LuggageItem> _items = [...widget.initialItems];
  late bool _showForm = _items.isEmpty;

  @override
  void dispose() {
    _type.dispose();
    _size.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _type.text.trim().isNotEmpty && _size.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    setState(() {
      _items.add(
        LuggageItem(
          type: _type.text.trim(),
          size: _size.text.trim(),
          weightKg: int.tryParse(_weight.text),
        ),
      );
      _type.clear();
      _size.clear();
      _weight.clear();
      _showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: widget.title,
      onBack: widget.onBack,
      confirmLabel: 'Continuar',
      onConfirm: () => widget.onContinue(List.unmodifiable(_items)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _items.length; index++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.luggage, color: AppColors.highlight),
              title: Text(
                _items[index].summary,
                style: const TextStyle(color: AppColors.sheetTextPrimary),
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _items.removeAt(index)),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.sheetTextSecondary,
                ),
              ),
            ),
          if (_showForm) _buildForm(),
          if (!_showForm)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                key: const Key('add_luggage'),
                onPressed: () => setState(() => _showForm = true),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.highlight,
                  foregroundColor: AppColors.onPrimary,
                ),
                icon: const Icon(Icons.add),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          key: const Key('luggage_type'),
          controller: _type,
          label: 'Tipo',
        ),
        const SizedBox(height: 10),
        _field(
          key: const Key('luggage_size'),
          controller: _size,
          label: 'Tamanho',
        ),
        const SizedBox(height: 10),
        _field(
          key: const Key('luggage_weight'),
          controller: _weight,
          label: 'Peso (opcional)',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Guardar'),
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
