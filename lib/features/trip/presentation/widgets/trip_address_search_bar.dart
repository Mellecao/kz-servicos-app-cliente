import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/models/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/data/services/places_autocomplete_service.dart';

class TripAddressSearchBar extends StatefulWidget {
  final LatLng? location;
  final ValueChanged<PlacePrediction>? onAddressSelected;

  const TripAddressSearchBar({
    super.key,
    this.location,
    this.onAddressSelected,
  });

  @override
  State<TripAddressSearchBar> createState() => _TripAddressSearchBarState();
}

class _TripAddressSearchBarState extends State<TripAddressSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PlacesAutocompleteService _service = PlacesAutocompleteService();

  List<PlacePrediction> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();

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
        location: widget.location,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  void _onSuggestionTap(PlacePrediction prediction) {
    _controller.text = prediction.description;
    setState(() => _suggestions = []);
    _focusNode.unfocus();
    widget.onAddressSelected?.call(prediction);
  }

  void _onClear() {
    _controller.clear();
    setState(() {
      _suggestions = [];
      _isLoading = false;
    });
  }

  Widget _buildHighlightedText(PlacePrediction prediction) {
    final text = prediction.description;
    final matches = List.of(prediction.matchedSubstrings)
      ..sort((a, b) => a.offset.compareTo(b.offset));

    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final match in matches) {
      if (match.offset > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, match.offset)),
        );
      }
      final end = (match.offset + match.length).clamp(0, text.length);
      spans.add(
        TextSpan(
          text: text.substring(match.offset, end),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      cursor = end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: spans,
      ),
    );
  }

  bool get _isExpanded =>
      _suggestions.isNotEmpty || (_isLoading && _controller.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchInput(),
        _buildSuggestionsAccordion(),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft:
              _isExpanded ? Radius.zero : const Radius.circular(14),
          bottomRight:
              _isExpanded ? Radius.zero : const Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Para aonde vamos hoje?',
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.30),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.black45,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: _onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsAccordion() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: _isExpanded ? _buildSuggestionsList() : const SizedBox.shrink(),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        child: _isLoading && _suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, i) => const Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 16,
                ),
                itemBuilder: (ctx, i) =>
                    _SuggestionItem(
                      prediction: _suggestions[i],
                      highlightedText: _buildHighlightedText(_suggestions[i]),
                      onTap: () => _onSuggestionTap(_suggestions[i]),
                    ),
              ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final PlacePrediction prediction;
  final Widget highlightedText;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.prediction,
    required this.highlightedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.black38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: highlightedText),
          ],
        ),
      ),
    );
  }
}
