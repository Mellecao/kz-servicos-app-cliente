import 'package:flutter/material.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/domain/category_search.dart';

/// Campo "Que serviço procura?" com autocomplete das categorias de serviço.
///
/// Mesmo visual do campo de endereço da tela de viagens (cartão branco, lista
/// de sugestões colada por baixo), mas filtra as [categories] localmente, sem
/// diferenciar acentos nem maiúsculas.
class ServiceSearchBar extends StatefulWidget {
  const ServiceSearchBar({
    super.key,
    required this.categories,
    required this.onSelected,
    this.onCleared,
  });

  final List<ServiceCategory> categories;
  final ValueChanged<ServiceCategory> onSelected;
  final VoidCallback? onCleared;

  @override
  State<ServiceSearchBar> createState() => _ServiceSearchBarState();
}

class _ServiceSearchBarState extends State<ServiceSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Nome da categoria escolhida: enquanto o texto for igual a ele, a lista
  /// de sugestões fica fechada.
  String? _pickedName;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _hasQuery =>
      _controller.text.trim().isNotEmpty && _controller.text != _pickedName;

  void _pick(ServiceCategory category) {
    _pickedName = category.name;
    _controller.text = category.name;
    _focusNode.unfocus();
    widget.onSelected(category);
  }

  void _clear() {
    _pickedName = null;
    _controller.clear();
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _hasQuery
        ? filterCategories(widget.categories, _controller.text)
        : const <ServiceCategory>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInput(expanded: _hasQuery),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _hasQuery ? _buildList(matches) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInput({required bool expanded}) {
    const radius = Radius.circular(14);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: expanded ? Radius.zero : radius,
          bottomRight: expanded ? Radius.zero : radius,
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
        key: const Key('service_search_field'),
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Que serviço procura?',
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.30),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: _clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ServiceCategory> matches) {
    const radius = Radius.circular(14);
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: radius,
          bottomRight: radius,
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
          bottomLeft: radius,
          bottomRight: radius,
        ),
        child: matches.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    Icon(Icons.search_off_rounded, color: Colors.black38),
                    SizedBox(width: 12),
                    Text(
                      'Nenhum serviço encontrado',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: matches.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 64, endIndent: 16),
                itemBuilder: (_, i) => _SuggestionItem(
                  key: ValueKey('suggestion-${matches[i].id}'),
                  category: matches[i],
                  onTap: () => _pick(matches[i]),
                ),
              ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({
    super.key,
    required this.category,
    required this.onTap,
  });

  final ServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = category.description;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color.withValues(alpha: 0.14),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (description != null && description.trim().isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
