import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/quantity_selector.dart';

class PassengerDetailsPanel extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final bool isMinimized;
  final VoidCallback onRestore;

  const PassengerDetailsPanel({
    super.key,
    required this.onConfirm,
    required this.onBack,
    this.isMinimized = false,
    required this.onRestore,
  });

  @override
  State<PassengerDetailsPanel> createState() => PassengerDetailsPanelState();
}

class PassengerDetailsPanelState extends State<PassengerDetailsPanel> {
  int _adults = 1;
  bool _hasChildren = false;
  final TextEditingController _childrenDescriptionController =
      TextEditingController();
  bool _hasLuggage = false;
  final TextEditingController _luggageController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  TimeOfDay? _pickupTime;
  DateTime? _pickupDate;
  bool _isNow = true;
  bool _isToday = true;

  int get adults => _adults;
  bool get hasChildren => _hasChildren;
  String get childrenDescription => _childrenDescriptionController.text;
  bool get hasLuggage => _hasLuggage;
  String get luggageDescription => _luggageController.text;
  String get observation => _observationController.text;
  TimeOfDay? get pickupTime => _isNow ? TimeOfDay.now() : _pickupTime;
  DateTime? get pickupDate => _isToday ? DateTime.now() : _pickupDate;

  @override
  void dispose() {
    _luggageController.dispose();
    _childrenDescriptionController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_hasLuggage && _luggageController.text.trim().isEmpty) return false;
    if (!_isNow && _pickupTime == null) return false;
    if (!_isToday && _pickupDate == null) return false;
    if (_hasChildren &&
        _childrenDescriptionController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  String get _summaryDate {
    if (_isToday) return 'Hoje';
    if (_pickupDate != null) {
      return '${_pickupDate!.day.toString().padLeft(2, '0')}/${_pickupDate!.month.toString().padLeft(2, '0')}';
    }
    return 'Hoje';
  }

  String get _summaryTime {
    if (_isNow) return 'Agora';
    if (_pickupTime != null) {
      return '${_pickupTime!.hour.toString().padLeft(2, '0')}:${_pickupTime!.minute.toString().padLeft(2, '0')}';
    }
    return 'Agora';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isMinimized ? widget.onRestore : () {},
      onVerticalDragUpdate: widget.isMinimized
          ? (details) {
              if (details.delta.dy < -3) widget.onRestore();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: widget.isMinimized ? 130 : screenHeight * 0.55,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: widget.isMinimized
            ? _buildMinimizedSummary()
            : _buildExpandedContent(),
      ),
    );
  }

  Widget _buildMinimizedSummary() {
    return Column(
      children: [
          _buildGrabber(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _summaryDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time_rounded,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  _summaryTime,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person_rounded, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '$_adults',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_up_rounded,
                    size: 24, color: Colors.grey[400]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildConfirmButton(),
          ),
        ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
        children: [
          _buildGrabber(),
          _buildTitleRow(),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildSectionTitle('Data e Horário'),
                const SizedBox(height: 12),
                _buildDateSelector(),
                const SizedBox(height: 12),
                _buildTimeSelector(),
                const SizedBox(height: 20),
                _buildSectionTitle('Passageiros'),
                const SizedBox(height: 12),
                _buildAdultsSelector(),
                const SizedBox(height: 16),
                _buildChildrenToggle(),
                if (_hasChildren) ...[
                  const SizedBox(height: 12),
                  _buildDescriptionField(
                    controller: _childrenDescriptionController,
                    hint: 'Ex: 2 crianças, idades 3 e 7 anos',
                  ),
                ],
                const SizedBox(height: 16),
                _buildLuggageToggle(),
                if (_hasLuggage) ...[
                  const SizedBox(height: 12),
                  _buildDescriptionField(
                    controller: _luggageController,
                    hint: 'Ex: 2 malas grandes e 1 mochila',
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 20),
                _buildSectionTitle('Forma de pagamento'),
                const SizedBox(height: 12),
                _buildPaymentMethod(),
                const SizedBox(height: 20),
                _buildSectionTitle('Observação'),
                const SizedBox(height: 12),
                _buildDescriptionField(
                  controller: _observationController,
                  hint: 'Ex: Preciso de ajuda com as malas, portão azul...',
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildConfirmButton(),
        ),
      ],
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'Detalhes da viagem',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAdultsSelector() {
    return Row(
      children: [
        const Text('Adultos', style: TextStyle(fontSize: 14)),
        const Spacer(),
        QuantitySelector(
          value: _adults,
          min: 1,
          max: 5,
          onChanged: (v) => setState(() => _adults = v),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.pix_rounded, size: 20, color: Colors.teal.shade600),
          const SizedBox(width: 10),
          const Text(
            'PIX',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Icon(Icons.check_circle_rounded,
              size: 20, color: AppColors.highlight),
        ],
      ),
    );
  }

  Widget _buildChildrenToggle() {
    return _buildToggleRow(
      label: 'Possui crianças?',
      value: _hasChildren,
      onChanged: (v) {
        setState(() {
          _hasChildren = v;
          if (!v) _childrenDescriptionController.clear();
        });
      },
    );
  }

  Widget _buildLuggageToggle() {
    return _buildToggleRow(
      label: 'Possui malas?',
      value: _hasLuggage,
      onChanged: (v) {
        setState(() {
          _hasLuggage = v;
          if (!v) _luggageController.clear();
        });
      },
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Switch(
          value: value,
          activeThumbColor: AppColors.highlight,
          activeTrackColor: AppColors.highlight.withValues(alpha: 0.4),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade300,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDescriptionField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.black.withValues(alpha: 0.3),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.highlight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      children: [
        const Text('Horário de embarque', style: TextStyle(fontSize: 14)),
        const Spacer(),
        _buildChip(
          label: 'Agora',
          selected: _isNow,
          onTap: () => setState(() => _isNow = true),
        ),
        const SizedBox(width: 8),
        _buildChip(
          label: _pickupTime != null && !_isNow
              ? '${_pickupTime!.hour.toString().padLeft(2, '0')}:${_pickupTime!.minute.toString().padLeft(2, '0')}'
              : 'Escolher',
          selected: !_isNow,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                _pickupTime = time;
                _isNow = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        const Text('Data de embarque', style: TextStyle(fontSize: 14)),
        const Spacer(),
        _buildChip(
          label: 'Hoje',
          selected: _isToday,
          onTap: () => setState(() => _isToday = true),
        ),
        const SizedBox(width: 8),
        _buildChip(
          label: _pickupDate != null && !_isToday
              ? '${_pickupDate!.day.toString().padLeft(2, '0')}/${_pickupDate!.month.toString().padLeft(2, '0')}'
              : 'Escolher',
          selected: !_isToday,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _pickupDate = date;
                _isToday = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.highlight : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isValid ? widget.onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Continuar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
