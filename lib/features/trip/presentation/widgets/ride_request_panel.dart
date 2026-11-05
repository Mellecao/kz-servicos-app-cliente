import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/address_editor_screen.dart';

typedef RideRequestSuggestionsLoader = AddressEditorSuggestionsLoader;

enum RideRequestMode { immediate, scheduled }

class RideRequestSelection {
  const RideRequestSelection({
    required this.outboundPickup,
    required this.outboundDropoff,
    required this.outboundStops,
    required this.isRoundTrip,
    this.returnPickup,
    this.returnDropoff,
    this.mode = RideRequestMode.immediate,
  });

  final PlacePrediction outboundPickup;
  final PlacePrediction outboundDropoff;
  final List<PlacePrediction> outboundStops;
  final bool isRoundTrip;
  final PlacePrediction? returnPickup;
  final PlacePrediction? returnDropoff;
  final RideRequestMode mode;
}

class RideRequestPanel extends StatefulWidget {
  const RideRequestPanel({
    super.key,
    required this.onConfirm,
    required this.onScheduleRequested,
    this.currentLocation,
    this.initialPickupAddress,
    this.onRoundTripChanged,
    this.onModeChanged,
    this.onSelectPickupOnMap,
    this.suggestionsLoader,
  });

  final ValueChanged<RideRequestSelection> onConfirm;

  /// Retained for source compatibility. Mode changes are local and this
  /// callback is intentionally not invoked when the user taps Agendar.
  final VoidCallback onScheduleRequested;
  final LatLng? currentLocation;
  final String? initialPickupAddress;
  final ValueChanged<bool>? onRoundTripChanged;
  final ValueChanged<RideRequestMode>? onModeChanged;
  final VoidCallback? onSelectPickupOnMap;
  final RideRequestSuggestionsLoader? suggestionsLoader;

  @override
  State<RideRequestPanel> createState() => _RideRequestPanelState();
}

class _RideRequestPanelState extends State<RideRequestPanel> {
  RideRequestMode _mode = RideRequestMode.immediate;
  bool _isRoundTrip = false;
  AddressEditorSelection? _addresses;

  PlacePrediction get _initialPickup => PlacePrediction(
    placeId: '_current_location_',
    description: widget.initialPickupAddress?.trim().isNotEmpty == true
        ? widget.initialPickupAddress!.trim()
        : 'Localização atual',
    matchedSubstrings: const [],
  );

  void _setMode(RideRequestMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      if (mode == RideRequestMode.immediate && _isRoundTrip) {
        _isRoundTrip = false;
        widget.onRoundTripChanged?.call(false);
      }
    });
    widget.onModeChanged?.call(mode);
  }

  void _setRoundTrip(bool value) {
    if (_mode == RideRequestMode.immediate || _isRoundTrip == value) return;
    setState(() {
      _isRoundTrip = value;
      final addresses = _addresses;
      if (value &&
          addresses != null &&
          (addresses.returnPickup == null || addresses.returnDropoff == null)) {
        _addresses = AddressEditorSelection(
          outboundPickup: addresses.outboundPickup,
          outboundDropoff: addresses.outboundDropoff,
          outboundStops: addresses.outboundStops,
          returnPickup: addresses.outboundDropoff,
          returnDropoff: addresses.outboundPickup,
        );
      }
    });
    widget.onRoundTripChanged?.call(value);
  }

  Future<void> _openEditor() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (routeContext) => AddressEditorScreen(
          isRoundTrip: _isRoundTrip,
          initialPickup: _addresses?.outboundPickup ?? _initialPickup,
          initialSelection: _addresses,
          currentLocation: widget.currentLocation,
          suggestionsLoader: widget.suggestionsLoader,
          onSelectOnMap: widget.onSelectPickupOnMap,
          onSaved: (selection) {
            setState(() => _addresses = selection);
            Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
  }

  void _confirm() {
    final addresses = _addresses;
    if (addresses == null ||
        (_isRoundTrip &&
            (addresses.returnPickup == null ||
                addresses.returnDropoff == null))) {
      return;
    }
    widget.onConfirm(
      RideRequestSelection(
        outboundPickup: addresses.outboundPickup,
        outboundDropoff: addresses.outboundDropoff,
        outboundStops: addresses.outboundStops,
        isRoundTrip: _isRoundTrip,
        returnPickup: _isRoundTrip ? addresses.returnPickup : null,
        returnDropoff: _isRoundTrip ? addresses.returnDropoff : null,
        mode: _mode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sheetBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 128),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeSlider(),
              const SizedBox(height: 12),
              _addressSummary(),
              if (_mode == RideRequestMode.scheduled) ...[
                const SizedBox(height: 10),
                _tripSlider(),
              ],
              if (_addresses != null &&
                  (!_isRoundTrip ||
                      (_addresses!.returnPickup != null &&
                          _addresses!.returnDropoff != null))) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.highlight,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: const Text(
                      'Avançar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSlider() {
    return _animatedSlider(
      leftLabel: 'Viagem agora',
      rightLabel: 'Agendar',
      leftSelected: _mode == RideRequestMode.immediate,
      onLeft: () => _setMode(RideRequestMode.immediate),
      onRight: () => _setMode(RideRequestMode.scheduled),
    );
  }

  Widget _tripSlider() {
    return _animatedSlider(
      leftLabel: 'Somente ida',
      rightLabel: 'Ida e volta',
      leftSelected: !_isRoundTrip,
      onLeft: () => _setRoundTrip(false),
      onRight: () => _setRoundTrip(true),
    );
  }

  Widget _animatedSlider({
    required String leftLabel,
    required String rightLabel,
    required bool leftSelected,
    required VoidCallback onLeft,
    required VoidCallback onRight,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: leftSelected
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _sliderTap(leftLabel, leftSelected, onLeft)),
              Expanded(child: _sliderTap(rightLabel, !leftSelected, onRight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderTap(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _addressSummary() {
    final pickup =
        _addresses?.outboundPickup.description ?? _initialPickup.description;
    final dropoff = _addresses?.outboundDropoff.description;
    return InkWell(
      key: const Key('open_address_editor'),
      borderRadius: BorderRadius.circular(26),
      onTap: _openEditor,
      child: Column(
        children: [
          _summaryCard(
            key: const Key('outbound_address_card'),
            children: [
              _summaryRow('Partida', pickup, Icons.trip_origin),
              const Divider(color: Color(0xFF3A3A3A)),
              _summaryRow(
                'Destino',
                dropoff ?? 'Toque para inserir o destino',
                Icons.location_on,
              ),
              if ((_addresses?.outboundStops.length ?? 0) > 0)
                for (
                  var index = 0;
                  index < _addresses!.outboundStops.length;
                  index++
                ) ...[
                  const Divider(color: Color(0xFF3A3A3A)),
                  _summaryRow(
                    'Parada ${index + 1}',
                    _addresses!.outboundStops[index].description,
                    Icons.more_vert,
                  ),
                ],
            ],
          ),
          if (_isRoundTrip) ...[
            _addressCardsDots(),
            _summaryCard(
              key: const Key('return_address_card'),
              children: [
                _summaryRow(
                  'Embarque da volta',
                  _addresses?.returnPickup?.description ??
                      dropoff ??
                      'Destino da ida',
                  Icons.replay_circle_filled,
                ),
                const Divider(color: Color(0xFF3A3A3A)),
                _summaryRow(
                  'Destino da volta',
                  _addresses?.returnDropoff?.description ?? pickup,
                  Icons.flag,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard({required Key key, required List<Widget> children}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(children: children),
    );
  }

  Widget _addressCardsDots() {
    return SizedBox(
      key: const Key('address_cards_dots'),
      height: 26,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (_) => const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.highlight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.sheetTextSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.sheetTextSecondary),
      ],
    );
  }
}
