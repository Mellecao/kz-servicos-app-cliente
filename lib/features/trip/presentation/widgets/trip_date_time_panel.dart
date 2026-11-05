import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripDateTimePanel extends StatefulWidget {
  const TripDateTimePanel({
    super.key,
    required this.onBack,
    required this.onConfirm,
    this.initialValue,
  });

  final VoidCallback onBack;
  final ValueChanged<DateTime> onConfirm;
  final DateTime? initialValue;

  @override
  State<TripDateTimePanel> createState() => _TripDateTimePanelState();
}

class _TripDateTimePanelState extends State<TripDateTimePanel> {
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      _date = initial;
      _time = TimeOfDay.fromDateTime(initial);
    }
  }

  bool get _isValid {
    if (_date == null || _time == null) return false;
    final value = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    return value.isAfter(DateTime.now());
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final suggested = now.add(const Duration(hours: 1));
    final value = await showDatePicker(
      context: context,
      initialDate: _date ?? suggested,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final suggested = now.add(const Duration(hours: 1));
    final value = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.fromDateTime(suggested),
    );
    if (value != null && mounted) setState(() => _time = value);
  }

  void _confirm() {
    final date = _date!;
    final time = _time!;
    widget.onConfirm(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const Key('date_time_sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .68,
      ),
      child: Material(
        color: AppColors.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.sheetTextPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Data e Hora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.sheetTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.sheetSurface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      _row(
                        label: 'Data',
                        value: _date == null
                            ? 'Selecionar Data...'
                            : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
                        onTap: _pickDate,
                      ),
                      const Divider(height: 1, color: Color(0xFF3A3A3A)),
                      _row(
                        label: 'Hora',
                        value: _time == null
                            ? 'Selecionar Hora...'
                            : _time!.format(context),
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isValid ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.highlight,
                      disabledBackgroundColor: const Color(0xFF3A3A3A),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Avançar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF3A3A3A),
        radius: 18,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.sheetTextSecondary,
          fontSize: 11,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: AppColors.sheetTextPrimary, fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}
