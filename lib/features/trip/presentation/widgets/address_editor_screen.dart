import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/places_autocomplete_service.dart';

typedef AddressEditorSuggestionsLoader =
    Future<List<PlacePrediction>> Function({
      required String input,
      LatLng? location,
    });

class AddressEditorSelection {
  const AddressEditorSelection({
    required this.outboundPickup,
    required this.outboundDropoff,
    required this.outboundStops,
    this.returnPickup,
    this.returnDropoff,
  });

  final PlacePrediction outboundPickup;
  final PlacePrediction outboundDropoff;
  final List<PlacePrediction> outboundStops;
  final PlacePrediction? returnPickup;
  final PlacePrediction? returnDropoff;
}

class AddressEditorScreen extends StatefulWidget {
  const AddressEditorScreen({
    super.key,
    required this.isRoundTrip,
    required this.onSaved,
    this.initialPickup,
    this.initialSelection,
    this.currentLocation,
    this.suggestionsLoader,
    this.onClose,
    this.onSelectOnMap,
  });

  final bool isRoundTrip;
  final ValueChanged<AddressEditorSelection> onSaved;
  final PlacePrediction? initialPickup;
  final AddressEditorSelection? initialSelection;
  final LatLng? currentLocation;
  final AddressEditorSuggestionsLoader? suggestionsLoader;
  final VoidCallback? onClose;
  final VoidCallback? onSelectOnMap;

  @override
  State<AddressEditorScreen> createState() => _AddressEditorScreenState();
}

class _AddressEditorScreenState extends State<AddressEditorScreen> {
  static const _outPickup = 'outbound_pickup';
  static const _outDropoff = 'outbound_dropoff';
  static const _returnPickup = 'return_pickup';
  static const _returnDropoff = 'return_dropoff';

  final _service = PlacesAutocompleteService();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, PlacePrediction?> _selected = {};
  final List<String> _stops = [];
  Timer? _debounce;
  String? _activeField;
  List<PlacePrediction> _suggestions = const [];
  bool _loading = false;
  bool _returnPickupEdited = false;
  bool _returnDropoffEdited = false;

  @override
  void initState() {
    super.initState();
    for (final field in [
      _outPickup,
      _outDropoff,
      _returnPickup,
      _returnDropoff,
    ]) {
      _addField(field);
    }
    final initial = widget.initialSelection;
    _set(_outPickup, initial?.outboundPickup ?? widget.initialPickup);
    _set(_outDropoff, initial?.outboundDropoff);
    _set(
      _returnPickup,
      initial?.returnPickup ??
          (widget.isRoundTrip ? initial?.outboundDropoff : null),
    );
    _set(
      _returnDropoff,
      initial?.returnDropoff ??
          (widget.isRoundTrip
              ? (initial?.outboundPickup ?? widget.initialPickup)
              : null),
    );
    for (final stop in initial?.outboundStops ?? const <PlacePrediction>[]) {
      final field = 'stop_${_stops.length}';
      _addField(field);
      _stops.add(field);
      _set(field, stop);
    }
  }

  void _addField(String field) {
    final controller = TextEditingController();
    final focus = FocusNode();
    _controllers[field] = controller;
    _focusNodes[field] = focus;
    _selected[field] = null;
    controller.addListener(() => _changed(field));
    focus.addListener(() {
      if (focus.hasFocus && mounted) setState(() => _activeField = field);
    });
  }

  void _set(String field, PlacePrediction? prediction) {
    if (prediction == null) return;
    _controllers[field]!.text = prediction.description;
    _selected[field] = prediction;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focus in _focusNodes.values) {
      focus.dispose();
    }
    super.dispose();
  }

  void _changed(String field) {
    final text = _controllers[field]!.text;
    if (text != _selected[field]?.description) _selected[field] = null;
    if (_activeField != field) return;
    if (field == _returnPickup) _returnPickupEdited = true;
    if (field == _returnDropoff) _returnDropoffEdited = true;
    _debounce?.cancel();
    final query = text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final loader = widget.suggestionsLoader;
      final results = loader == null
          ? await _service.fetchSuggestions(
              input: query,
              location: widget.currentLocation,
            )
          : await loader(input: query, location: widget.currentLocation);
      if (!mounted || _activeField != field) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  void _select(PlacePrediction prediction) {
    final field = _activeField;
    if (field == null) return;
    _set(field, prediction);
    if (widget.isRoundTrip) {
      if (field == _outDropoff && !_returnPickupEdited) {
        _set(_returnPickup, prediction);
      } else if (field == _outPickup && !_returnDropoffEdited) {
        _set(_returnDropoff, prediction);
      } else if (field == _returnPickup) {
        _returnPickupEdited = true;
      } else if (field == _returnDropoff) {
        _returnDropoffEdited = true;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _loading = false;
    });
  }

  void _addStop() {
    if (_stops.length >= 3) return;
    final field = 'stop_${_stops.length}';
    _addField(field);
    setState(() => _stops.add(field));
  }

  bool get _outboundComplete =>
      _selected[_outPickup] != null &&
      _selected[_outDropoff] != null &&
      _stops.every((field) => _selected[field] != null);

  bool get _returnComplete =>
      _selected[_returnPickup] != null && _selected[_returnDropoff] != null;

  void _save() {
    if (!_outboundComplete || (widget.isRoundTrip && !_returnComplete)) return;
    widget.onSaved(
      AddressEditorSelection(
        outboundPickup: _selected[_outPickup]!,
        outboundDropoff: _selected[_outDropoff]!,
        outboundStops: [for (final field in _stops) _selected[field]!],
        returnPickup: widget.isRoundTrip ? _selected[_returnPickup] : null,
        returnDropoff: widget.isRoundTrip ? _selected[_returnDropoff] : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sheetBackground,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed:
                          widget.onClose ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  Text(
                    'Inserir moradas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 28, 17, 18),
                child: Column(
                  children: [
                    if (widget.isRoundTrip) ...[
                      const _AddressSectionTitle('Moradas de ida'),
                      const SizedBox(height: 8),
                    ],
                    _addressCard(_outPickup, _outDropoff, showStops: true),
                    if (widget.isRoundTrip) ...[
                      const SizedBox(height: 20),
                      const _AddressSectionTitle('Moradas de volta'),
                      const SizedBox(height: 8),
                      _addressCard(
                        _returnPickup,
                        _returnDropoff,
                        showStops: false,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_loading) const LinearProgressIndicator(),
                    for (final prediction in _suggestions)
                      ListTile(
                        onTap: () => _select(prediction),
                        title: Text(
                          prediction.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (widget.onSelectOnMap != null) ...[
                      const Divider(color: AppColors.sheetTextSecondary),
                      ListTile(
                        onTap: widget.onSelectOnMap,
                        title: const Text(
                          'Inserir local no mapa manualmente',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_outboundComplete &&
                          (!widget.isRoundTrip || _returnComplete))
                      ? _save
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text(
                    'Guardar moradas',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(
    String pickupField,
    String dropoffField, {
    required bool showStops,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF555555),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _field(pickupField, 'Partida'),
          const SizedBox(height: 10),
          if (showStops)
            for (var index = 0; index < _stops.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _field(_stops[index], 'Parada ${index + 1}'),
              ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _field(dropoffField, 'Destino')),
              if (showStops) ...[
                const SizedBox(width: 10),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: IconButton.filled(
                    key: const Key('add_outbound_stop'),
                    onPressed: _stops.length == 3 ? null : _addStop,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.highlight,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String field, String label) {
    return Container(
      key: Key('address_field_$field'),
      height: 68,
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF797979),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD0D0D0),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: TextField(
              key: Key('address_editor_$field'),
              controller: _controllers[field],
              focusNode: _focusNodes[field],
              onTap: () => setState(() => _activeField = field),
              style: const TextStyle(color: Colors.white),
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSectionTitle extends StatelessWidget {
  const _AddressSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
