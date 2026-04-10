import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/places_autocomplete_service.dart';

class AddressSearchSheet extends StatefulWidget {
  final LatLng? currentLocation;
  final String? initialPickupAddress;
  final ValueChanged<PlacePrediction> onDestinationSelected;
  final ValueChanged<PlacePrediction> onPickupSelected;
  final ValueChanged<PlacePrediction> onStopSelected;
  final VoidCallback onDismissed;
  final VoidCallback onSelectPickupOnMap;
  final VoidCallback onConfirmAddresses;

  const AddressSearchSheet({
    super.key,
    this.currentLocation,
    this.initialPickupAddress,
    required this.onDestinationSelected,
    required this.onPickupSelected,
    required this.onStopSelected,
    required this.onDismissed,
    required this.onSelectPickupOnMap,
    required this.onConfirmAddresses,
  });

  @override
  State<AddressSearchSheet> createState() => AddressSearchSheetState();
}

class AddressSearchSheetState extends State<AddressSearchSheet> {
  final _destinationController = TextEditingController();
  final _pickupController = TextEditingController();
  final _destinationFocus = FocusNode();
  final _pickupFocus = FocusNode();
  final _service = PlacesAutocompleteService();

  final List<TextEditingController> _stopControllers = [];
  final List<FocusNode> _stopFocusNodes = [];

  List<PlacePrediction> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  /// Which field is active: 'pickup', 'destination', 'stop_0', 'stop_1', etc.
  String _activeField = 'destination';
  bool _pickupIsDefault = true;

  @override
  void initState() {
    super.initState();
    _pickupController.text = 'Minha localização atual';
    _destinationController.addListener(_onDestinationChanged);
    _pickupController.addListener(_onPickupChanged);
    _destinationFocus.addListener(() {
      if (_destinationFocus.hasFocus) {
        setState(() => _activeField = 'destination');
      }
    });
    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus) {
        if (_pickupIsDefault) {
          _pickupController.removeListener(_onPickupChanged);
          _pickupController.clear();
          _pickupController.addListener(_onPickupChanged);
          _pickupIsDefault = false;
        }
        setState(() => _activeField = 'pickup');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _destinationFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _pickupController.dispose();
    _destinationFocus.dispose();
    _pickupFocus.dispose();
    for (final c in _stopControllers) {
      c.dispose();
    }
    for (final f in _stopFocusNodes) {
      f.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  void _onDestinationChanged() => _onTextChanged('destination');
  void _onPickupChanged() => _onTextChanged('pickup');

  void _onTextChanged(String field) {
    _debounce?.cancel();
    final ctrl = _controllerForField(field);
    if (ctrl == null) return;
    final query = ctrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _service.fetchSuggestions(
        input: query,
        location: widget.currentLocation,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
          _activeField = field;
        });
      }
    });
  }

  TextEditingController? _controllerForField(String field) {
    if (field == 'pickup') return _pickupController;
    if (field == 'destination') return _destinationController;
    final idx = int.tryParse(field.replaceFirst('stop_', ''));
    if (idx != null && idx < _stopControllers.length) {
      return _stopControllers[idx];
    }
    return null;
  }

  void _onSuggestionTap(PlacePrediction prediction) {
    final ctrl = _controllerForField(_activeField);
    if (ctrl == null) return;

    // Remove listener, set text, re-add listener
    final listener = _listenerForField(_activeField);
    if (listener != null) ctrl.removeListener(listener);
    ctrl.text = prediction.description;
    if (listener != null) ctrl.addListener(listener);
    setState(() => _suggestions = []);

    if (_activeField == 'destination') {
      widget.onDestinationSelected(prediction);
      // If pickup is still default, auto-set current location as pickup
      if (_pickupIsDefault && widget.currentLocation != null) {
        widget.onPickupSelected(
          PlacePrediction(
            placeId: '_current_location_',
            description: 'Minha localização atual',
            matchedSubstrings: [],
          ),
        );
      } else {
        _pickupFocus.requestFocus();
      }
    } else if (_activeField == 'pickup') {
      widget.onPickupSelected(prediction);
    } else if (_activeField.startsWith('stop_')) {
      widget.onStopSelected(prediction);
    }
  }

  VoidCallback? _listenerForField(String field) {
    if (field == 'pickup') return _onPickupChanged;
    if (field == 'destination') return _onDestinationChanged;
    final idx = int.tryParse(field.replaceFirst('stop_', ''));
    if (idx != null && idx < _stopControllers.length) {
      return () => _onTextChanged('stop_$idx');
    }
    return null;
  }

  void _addStop() {
    if (_stopControllers.length >= 3) return;
    final idx = _stopControllers.length;
    final ctrl = TextEditingController();
    final focus = FocusNode();
    ctrl.addListener(() => _onTextChanged('stop_$idx'));
    focus.addListener(() {
      if (focus.hasFocus) setState(() => _activeField = 'stop_$idx');
    });
    setState(() {
      _stopControllers.add(ctrl);
      _stopFocusNodes.add(focus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focus.requestFocus();
    });
  }

  void _removeStop(int index) {
    _stopControllers[index].dispose();
    _stopFocusNodes[index].dispose();
    setState(() {
      _stopControllers.removeAt(index);
      _stopFocusNodes.removeAt(index);
      if (_activeField.startsWith('stop_')) {
        _activeField = 'destination';
      }
    });
  }

  bool get _canConfirm =>
      _destinationController.text.trim().isNotEmpty;

  void setPickupAddress(String address) {
    _pickupController.text = address;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildInputs(),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: _buildSuggestionsList(),
                ),
              ),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 18, left: 4, right: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: Colors.black87,
            onPressed: widget.onDismissed,
          ),
          const Expanded(
            child: Text(
              'Buscar endereço',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical dots column
          Padding(
            padding: const EdgeInsets.only(top: 18, right: 12),
            child: Column(
              children: [
                _buildDot(Colors.green),
                ..._buildConnectorDots(),
                _buildDot(Colors.orange),
                for (int i = 0; i < _stopControllers.length; i++) ...[
                  ..._buildConnectorDots(),
                  _buildDot(Colors.black87),
                ],
              ],
            ),
          ),
          // Input fields
          Expanded(
            child: Column(
              children: [
                _buildSearchField(
                  controller: _pickupController,
                  focusNode: _pickupFocus,
                  hint: 'De onde?',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSearchField(
                        controller: _destinationController,
                        focusNode: _destinationFocus,
                        hint: 'Para onde vamos?',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAddStopButton(),
                  ],
                ),
                for (int i = 0; i < _stopControllers.length; i++) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchField(
                          controller: _stopControllers[i],
                          focusNode: _stopFocusNodes[i],
                          hint: 'Parada ${i + 1}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeStop(i),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.red.shade200,
                            ),
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  List<Widget> _buildConnectorDots() {
    return List.generate(
      3,
      (_) => Container(
        width: 2,
        height: 8,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildAddStopButton() {
    if (_stopControllers.length >= 3) {
      return const SizedBox(width: 48);
    }
    return GestureDetector(
      onTap: _addStop,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.black54),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.30),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.black38,
                  ),
                  onPressed: () {
                    controller.clear();
                    setState(() => _suggestions = []);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading && _suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    final showMapOption = _activeField == 'pickup';
    final count = _suggestions.length + (showMapOption ? 1 : 0);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: count,
      separatorBuilder: (_, i) => const Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
      ),
      itemBuilder: (ctx, i) {
        if (showMapOption && i == _suggestions.length) {
          return _buildMapOption();
        }
        final pred = _suggestions[i];
        return InkWell(
          onTap: () => _onSuggestionTap(pred),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.black38,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    pred.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapOption() {
    return InkWell(
      onTap: () {
        setState(() => _suggestions = []);
        widget.onSelectPickupOnMap();
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.map_rounded, color: Colors.blue, size: 22),
            SizedBox(width: 14),
            Text(
              'Selecionar local no mapa',
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _canConfirm ? widget.onConfirmAddresses : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.highlight,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Confirmar endereços',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
