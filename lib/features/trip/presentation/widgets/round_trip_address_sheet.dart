import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/places_autocomplete_service.dart';

typedef RoundTripSuggestionsLoader =
    Future<List<PlacePrediction>> Function({
      required String input,
      LatLng? location,
    });

class RoundTripAddressSelection {
  const RoundTripAddressSelection({
    required this.outboundPickup,
    required this.outboundDropoff,
    required this.returnPickup,
    required this.returnDropoff,
  });

  final PlacePrediction outboundPickup;
  final PlacePrediction outboundDropoff;
  final PlacePrediction returnPickup;
  final PlacePrediction returnDropoff;
}

class RoundTripAddressSheet extends StatefulWidget {
  const RoundTripAddressSheet({
    super.key,
    required this.onDismissed,
    required this.onConfirmed,
    this.currentLocation,
    this.initialOutboundPickup,
    this.suggestionsLoader,
  });

  final VoidCallback onDismissed;
  final ValueChanged<RoundTripAddressSelection> onConfirmed;
  final LatLng? currentLocation;
  final PlacePrediction? initialOutboundPickup;
  final RoundTripSuggestionsLoader? suggestionsLoader;

  @override
  State<RoundTripAddressSheet> createState() => _RoundTripAddressSheetState();
}

class _RoundTripAddressSheetState extends State<RoundTripAddressSheet> {
  static const _outboundPickup = 'outbound_pickup';
  static const _outboundDropoff = 'outbound_dropoff';
  static const _returnPickup = 'return_pickup';
  static const _returnDropoff = 'return_dropoff';

  final _service = PlacesAutocompleteService();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, PlacePrediction?> _selected = {};

  Timer? _debounce;
  List<PlacePrediction> _suggestions = const [];
  String _activeField = _outboundDropoff;
  bool _isLoading = false;
  bool _returnPickupWasEdited = false;
  bool _returnDropoffWasEdited = false;

  @override
  void initState() {
    super.initState();
    for (final field in [
      _outboundPickup,
      _outboundDropoff,
      _returnPickup,
      _returnDropoff,
    ]) {
      _controllers[field] = TextEditingController();
      _focusNodes[field] = FocusNode();
      _selected[field] = null;
      _controllers[field]!.addListener(() => _onTextChanged(field));
      _focusNodes[field]!.addListener(() {
        if (_focusNodes[field]!.hasFocus && mounted) {
          setState(() => _activeField = field);
        }
      });
    }

    final initialPickup = widget.initialOutboundPickup;
    if (initialPickup != null) {
      _setPrediction(_outboundPickup, initialPickup, notify: false);
      _setPrediction(_returnDropoff, initialPickup, notify: false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[_outboundDropoff]!.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<List<PlacePrediction>> _loadSuggestions(String input) {
    final loader = widget.suggestionsLoader;
    if (loader != null) {
      return loader(input: input, location: widget.currentLocation);
    }
    return _service.fetchSuggestions(
      input: input,
      location: widget.currentLocation,
    );
  }

  void _onTextChanged(String field) {
    if (_controllers[field]!.text != _selected[field]?.description) {
      _selected[field] = null;
    }
    if (field != _activeField) return;

    _debounce?.cancel();
    final query = _controllers[field]!.text.trim();
    if (query.length < 3) {
      if (mounted) {
        setState(() {
          _suggestions = const [];
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _loadSuggestions(query);
      if (!mounted || field != _activeField) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    });
  }

  void _setPrediction(
    String field,
    PlacePrediction prediction, {
    bool notify = true,
  }) {
    final controller = _controllers[field]!;
    controller.text = prediction.description;
    _selected[field] = prediction;
    if (notify && mounted) setState(() {});
  }

  void _selectSuggestion(PlacePrediction prediction) {
    final field = _activeField;
    _setPrediction(field, prediction, notify: false);

    if (field == _outboundDropoff && !_returnPickupWasEdited) {
      _setPrediction(_returnPickup, prediction, notify: false);
    } else if (field == _outboundPickup && !_returnDropoffWasEdited) {
      _setPrediction(_returnDropoff, prediction, notify: false);
    } else if (field == _returnPickup) {
      _returnPickupWasEdited = true;
    } else if (field == _returnDropoff) {
      _returnDropoffWasEdited = true;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _isLoading = false;
    });
  }

  void _clearField(String field) {
    if (field == _returnPickup) _returnPickupWasEdited = true;
    if (field == _returnDropoff) _returnDropoffWasEdited = true;
    _selected[field] = null;
    _controllers[field]!.clear();
    setState(() => _suggestions = const []);
  }

  bool get _canContinue => _selected.values.every((value) => value != null);

  void _confirm() {
    if (!_canContinue) return;
    widget.onConfirmed(
      RoundTripAddressSelection(
        outboundPickup: _selected[_outboundPickup]!,
        outboundDropoff: _selected[_outboundDropoff]!,
        returnPickup: _selected[_returnPickup]!,
        returnDropoff: _selected[_returnDropoff]!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F7F9),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 18),
                    _buildLegCard(
                      title: 'Trajeto de ida',
                      subtitle: 'Defina onde a viagem começa e termina.',
                      badge: 'IDA',
                      color: AppColors.highlight,
                      fields: const [
                        (
                          _outboundPickup,
                          'Partida (ida)',
                          Icons.trip_origin_rounded,
                        ),
                        (
                          _outboundDropoff,
                          'Destino (ida)',
                          Icons.location_on_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildLegCard(
                      title: 'Trajeto de volta',
                      subtitle:
                          'Já preenchemos a rota inversa. Pode editar.',
                      badge: 'VOLTA',
                      color: const Color(0xFF20242B),
                      fields: const [
                        (
                          _returnPickup,
                          'Partida (volta)',
                          Icons.trip_origin_rounded,
                        ),
                        (_returnDropoff, 'Destino (volta)', Icons.home_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onDismissed,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Expanded(
            child: Text(
              'Moradas da viagem',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171A1F),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundTripHeroIcon(),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planeie a sua ida e volta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Informe os quatro pontos do trajeto para o motorista receber a rota completa.',
                  style: TextStyle(color: Color(0xFFB9BDC5), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required List<(String, String, IconData)> fields,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E9ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF777C85), fontSize: 13),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < fields.length; index++) ...[
            _buildAddressField(
              field: fields[index].$1,
              label: fields[index].$2,
              icon: fields[index].$3,
              accent: color,
            ),
            if (index != fields.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required String field,
    required String label,
    required IconData icon,
    required Color accent,
  }) {
    return Column(
      children: [
        TextField(
          key: Key('round_trip_$field'),
          controller: _controllers[field],
          focusNode: _focusNodes[field],
          textInputAction: TextInputAction.search,
          onTap: () => setState(() => _activeField = field),
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Procurar morada',
            prefixIcon: Icon(icon, color: accent, size: 21),
            suffixIcon: _controllers[field]!.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () => _clearField(field),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE4E6EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE4E6EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
        if (field == _activeField &&
            (_isLoading || _suggestions.isNotEmpty)) ...[
          const SizedBox(height: 8),
          _buildSuggestions(),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E6EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: _isLoading && _suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(22),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 52),
              itemBuilder: (context, index) {
                final prediction = _suggestions[index];
                return ListTile(
                  onTap: () => _selectSuggestion(prediction),
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.highlight,
                  ),
                  title: Text(
                    prediction.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E9ED))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _canContinue ? _confirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.highlight,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: const Color(0xFFD5D7DB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continuar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundTripHeroIcon extends StatelessWidget {
  const _RoundTripHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.highlight.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.sync_alt_rounded,
        color: AppColors.highlight,
        size: 27,
      ),
    );
  }
}
