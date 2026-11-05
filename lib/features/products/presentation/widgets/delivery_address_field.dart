import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/constants/app_maps.dart';
import 'package:kz_servicos_app/features/products/domain/checkout_form.dart';
import 'package:kz_servicos_app/features/products/presentation/widgets/product_ui.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/place_details_service.dart';
import 'package:kz_servicos_app/features/trip/data/services/places_autocomplete_service.dart';

/// Campo de morada com sugestões do Google Places (restrito a Angola, via
/// `PlacesAutocompleteService`). Ao escolher uma sugestão obtém as
/// coordenadas; se o utilizador editar o texto depois, as coordenadas são
/// descartadas (a morada escrita à mão continua válida).
class DeliveryAddressField extends StatefulWidget {
  const DeliveryAddressField({
    super.key,
    required this.controller,
    required this.onCoordinatesChanged,
    this.autocomplete,
    this.details,
  });

  final TextEditingController controller;
  final ValueChanged<LatLng?> onCoordinatesChanged;
  final PlacesAutocompleteService? autocomplete;
  final PlaceDetailsService? details;

  @override
  State<DeliveryAddressField> createState() => _DeliveryAddressFieldState();
}

class _DeliveryAddressFieldState extends State<DeliveryAddressField> {
  late final PlacesAutocompleteService _autocomplete =
      widget.autocomplete ?? PlacesAutocompleteService();
  late final PlaceDetailsService _details =
      widget.details ?? PlaceDetailsService();

  Timer? _debounce;
  List<PlacePrediction> _suggestions = const [];
  bool _loading = false;
  String? _selectedText;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_selectedText != null && value != _selectedText) {
      _selectedText = null;
      widget.onCoordinatesChanged(null);
    }
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 3 || value == _selectedText) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _autocomplete.fetchSuggestions(
        input: query,
        location: AppMaps.defaultCenter,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results.take(5).toList();
        _loading = false;
      });
    });
  }

  Future<void> _select(PlacePrediction prediction) async {
    FocusScope.of(context).unfocus();
    widget.controller.text = prediction.description;
    _selectedText = prediction.description;
    setState(() => _suggestions = const []);
    final latLng = await _details.getPlaceLatLng(prediction.placeId);
    if (!mounted || _selectedText != prediction.description) return;
    widget.onCoordinatesChanged(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('checkout_address'),
          controller: widget.controller,
          onChanged: _onChanged,
          validator: validateDeliveryAddress,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: AppColors.sheetTextPrimary),
          decoration: productInputDecoration(
            'Morada de entrega',
            hint: 'Ex.: Talatona, Luanda',
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.sheetTextSecondary,
                  ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.sheetSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (final p in _suggestions)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.highlight,
                    ),
                    title: Text(
                      p.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.sheetTextPrimary,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => _select(p),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
