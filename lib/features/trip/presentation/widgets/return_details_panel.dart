import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/passenger_form_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

class ReturnDetailsPanel extends StatefulWidget {
  const ReturnDetailsPanel({
    super.key,
    required this.currentClientName,
    required this.onBack,
    required this.onConfirm,
    this.currentClientAge,
    this.initialValue,
    this.initialPassengers = const [],
    this.initialLuggage = const [],
  });

  final String currentClientName;
  final int? currentClientAge;
  final PassengerFormData? initialValue;
  final List<TripPassengerData> initialPassengers;
  final List<TripLuggageData> initialLuggage;
  final VoidCallback onBack;
  final ValueChanged<PassengerFormData> onConfirm;

  @override
  State<ReturnDetailsPanel> createState() => _ReturnDetailsPanelState();
}

class _ReturnDetailsPanelState extends State<ReturnDetailsPanel> {
  DateTime? _date;
  TimeOfDay? _time;
  late final List<_PassengerRowControllers> _passengerRows;
  late final List<TripLuggageData> _luggage;
  final _luggageType = TextEditingController();
  final _luggageSize = TextEditingController();
  final _luggageWeight = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      _date = initial.scheduledDatetime;
      _time = TimeOfDay.fromDateTime(initial.scheduledDatetime);
    }
    final passengers = initial?.passengers.isNotEmpty == true
        ? initial!.passengers
        : widget.initialPassengers;
    _passengerRows = [
      for (final passenger in passengers.skip(1))
        _PassengerRowControllers(passenger.name, passenger.age),
    ];
    if (_passengerRows.isEmpty) _passengerRows.add(_PassengerRowControllers());
    _luggage = [
      ...(initial?.luggage.isNotEmpty == true
          ? initial!.luggage
          : widget.initialLuggage),
    ];
  }

  @override
  void dispose() {
    for (final row in _passengerRows) {
      row.dispose();
    }
    _luggageType.dispose();
    _luggageSize.dispose();
    _luggageWeight.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (selected != null) setState(() => _time = selected);
  }

  void _addPassengerRow() {
    setState(() => _passengerRows.add(_PassengerRowControllers()));
  }

  String _normalizedLuggageSize(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'p' || 'pequena' || 'pequeno' || 'small' => 'small',
      'm' || 'média' || 'media' || 'médio' || 'medio' || 'medium' => 'medium',
      'gg' || 'extra grande' || 'extra_large' => 'extra_large',
      _ => 'large',
    };
  }

  bool get _draftLuggageIsEmpty =>
      _luggageType.text.trim().isEmpty &&
      _luggageSize.text.trim().isEmpty &&
      _luggageWeight.text.trim().isEmpty;

  bool get _draftLuggageIsValid {
    if (_luggageType.text.trim().isEmpty || _luggageSize.text.trim().isEmpty) {
      return false;
    }
    final weightText = _luggageWeight.text.trim();
    if (weightText.isEmpty) return true;
    final weight = double.tryParse(weightText.replaceAll(',', '.'));
    return weight != null && weight > 0;
  }

  TripLuggageData _draftLuggage() => TripLuggageData(
    type: _luggageType.text.trim(),
    size: _normalizedLuggageSize(_luggageSize.text),
    weightKg: double.tryParse(_luggageWeight.text.replaceAll(',', '.')),
  );

  void _addLuggage() {
    if (!_draftLuggageIsValid) return;
    setState(() {
      _luggage.add(_draftLuggage());
      _luggageType.clear();
      _luggageSize.clear();
      _luggageWeight.clear();
    });
  }

  void _submit() {
    if (_date == null || _time == null) return;
    final passengers = <TripPassengerData>[
      TripPassengerData(
        name: widget.currentClientName,
        age:
            widget.currentClientAge ??
            (widget.initialPassengers.isNotEmpty
                ? widget.initialPassengers.first.age
                : 18),
      ),
    ];
    for (final row in _passengerRows) {
      if (row.isEmpty) continue;
      final age = int.tryParse(row.age.text);
      if (row.name.text.trim().isEmpty || age == null || age > 120) return;
      passengers.add(TripPassengerData(name: row.name.text.trim(), age: age));
    }
    if (!_draftLuggageIsEmpty && !_draftLuggageIsValid) return;
    final luggage = [..._luggage];
    if (_draftLuggageIsValid) luggage.add(_draftLuggage());
    final scheduled = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    widget.onConfirm(
      PassengerFormData(
        adults: passengers.where((passenger) => passenger.age > 10).length,
        scheduledDatetime: scheduled,
        hasChildren: passengers.any((passenger) => passenger.needsCarSeat),
        hasLuggage: luggage.isNotEmpty,
        passengers: passengers,
        luggage: luggage,
        isRoundTrip: true,
        paymentMethod: widget.initialValue?.paymentMethod ?? 'cash',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Container(
      key: const Key('return_details_panel'),
      width: double.infinity,
      height: screenHeight * .72,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 102),
              child: Column(
                children: [
                  _dateTimeCard(),
                  const SizedBox(height: 12),
                  _passengersCard(),
                  const SizedBox(height: 12),
                  _luggageCard(),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.highlight,
                        foregroundColor: AppColors.onPrimary,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Avançar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 53,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('return_details_back'),
              onPressed: widget.onBack,
              padding: const EdgeInsets.only(left: 18),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Text(
            'Detalhes da volta',
            style: TextStyle(
              color: AppColors.sheetTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeCard() {
    return Container(
      key: const Key('return_date_time_card'),
      height: 121,
      decoration: _cardDecoration,
      child: Column(
        children: [
          Expanded(
            child: _selectionRow(
              icon: Icons.calendar_month_rounded,
              label: 'Data',
              value: _date == null
                  ? 'Selecionar Data...'
                  : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
              onTap: _selectDate,
            ),
          ),
          const _CardDivider(),
          Expanded(
            child: _selectionRow(
              icon: Icons.access_time_rounded,
              label: 'Hora',
              value: _time == null
                  ? 'Selecionar Hora...'
                  : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
              onTap: _selectTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            _roundIcon(icon),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _labelStyle),
                const SizedBox(height: 3),
                Text(value, style: _valueStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passengersCard() {
    return Container(
      key: const Key('return_passengers_card'),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: _cardDecoration,
      child: Column(
        children: [
          SizedBox(
            height: 61,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _roundIcon(Icons.person_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Passageiros', style: _labelStyle),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.currentClientName} (Eu)',
                          style: _valueStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _addButton(
                    _addPassengerRow,
                    const Key('add_return_passenger'),
                  ),
                ],
              ),
            ),
          ),
          const _CardDivider(),
          for (var index = 0; index < _passengerRows.length; index++)
            SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    _roundIcon(Icons.person_outline_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _pillField(
                        key: Key('return_passenger_name_$index'),
                        controller: _passengerRows[index].name,
                        hint: 'Nome do Passageiro...',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pillField(
                        key: Key('return_passenger_age_$index'),
                        controller: _passengerRows[index].age,
                        hint: 'Idade...',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _luggageCard() {
    final first = _luggage.isEmpty ? null : _luggage.first;
    return Container(
      key: const Key('return_luggage_card'),
      constraints: const BoxConstraints(minHeight: 122),
      decoration: _cardDecoration,
      child: Column(
        children: [
          SizedBox(
            height: 61,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _roundIcon(Icons.luggage_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bagagem (opcional)', style: _labelStyle),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                first?.type ?? 'Nenhuma bagagem',
                                style: _valueStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (first != null) ...[
                              Text(_sizeLabel(first.size), style: _valueStyle),
                              const SizedBox(width: 36),
                              Text(
                                _weightLabel(first.weightKg),
                                style: _valueStyle,
                              ),
                              const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _addButton(_addLuggage, const Key('add_return_luggage')),
                ],
              ),
            ),
          ),
          const _CardDivider(),
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _roundIcon(Icons.luggage_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _pillField(
                      key: const Key('return_luggage_type'),
                      controller: _luggageType,
                      hint: 'Tipo da bagagem',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pillField(
                      key: const Key('return_luggage_size'),
                      controller: _luggageSize,
                      hint: 'Tamanho',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _pillField(
                      key: const Key('return_luggage_weight'),
                      controller: _luggageWeight,
                      hint: 'Peso (opcional)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _sizeLabel(String size) => switch (size) {
    'small' => 'P',
    'medium' => 'M',
    'extra_large' => 'GG',
    _ => 'G',
  };

  static String _weightLabel(double? weight) {
    if (weight == null) return '—';
    final text = weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toStringAsFixed(1).replaceAll('.', ',');
    return '${text}KG';
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF414141),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: AppColors.sheetTextSecondary),
    );
  }

  Widget _addButton(VoidCallback onTap, Key key) {
    return SizedBox(
      width: 31,
      height: 31,
      child: IconButton.filled(
        key: key,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.highlight,
          foregroundColor: AppColors.onPrimary,
        ),
        icon: const Icon(Icons.add_rounded, size: 23, weight: 900),
      ),
    );
  }

  Widget _pillField({
    required Key key,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 25,
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white, fontSize: 10),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF3B3B3B),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF777777), fontSize: 9),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.sheetSurface,
    borderRadius: BorderRadius.circular(29),
  );

  static const _labelStyle = TextStyle(
    color: AppColors.sheetTextSecondary,
    fontSize: 9,
  );

  static const _valueStyle = TextStyle(
    color: AppColors.sheetTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 7),
      child: Divider(height: 1, thickness: 1, color: Color(0xFF383838)),
    );
  }
}

class _PassengerRowControllers {
  _PassengerRowControllers([String name = '', int? age])
    : name = TextEditingController(text: name),
      age = TextEditingController(text: age?.toString() ?? '');

  final TextEditingController name;
  final TextEditingController age;

  bool get isEmpty => name.text.trim().isEmpty && age.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    age.dispose();
  }
}
