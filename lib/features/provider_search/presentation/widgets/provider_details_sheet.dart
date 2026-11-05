import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/provider_search/data/models/provider_search_result.dart';
import 'package:kz_servicos_app/features/provider_search/data/repositories/provider_search_repository.dart';

enum _Stage { details, form, sent }

/// Modal inferior com os dados do prestador tocado no mapa e o pedido direto:
/// detalhes (preço, tempo de resposta) → descrição do serviço → confirmação.
class ProviderDetailsSheet extends StatefulWidget {
  const ProviderDetailsSheet({
    super.key,
    required this.provider,
    required this.onRequest,
    required this.onViewRequest,
    this.category,
  });

  final ProviderSearchResult provider;

  /// Só para o ícone e a cor da categoria; opcional.
  final ServiceCategory? category;

  /// Envia o pedido ([description] já escrita) e devolve o id. Lança
  /// [ProviderSearchException] com a mensagem pt-AO a mostrar.
  final Future<String> Function(String description) onRequest;

  /// "Ver o meu pedido": recebe o id do pedido criado.
  final ValueChanged<String> onViewRequest;

  @override
  State<ProviderDetailsSheet> createState() => _ProviderDetailsSheetState();
}

class _ProviderDetailsSheetState extends State<ProviderDetailsSheet> {
  final TextEditingController _description = TextEditingController();
  _Stage _stage = _Stage.details;
  bool _sending = false;
  String? _error;
  String? _requestId;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _description.text.trim().isNotEmpty;

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final id = await widget.onRequest(_description.text);
      if (!mounted) return;
      setState(() {
        _requestId = id;
        _stage = _Stage.sent;
        _sending = false;
      });
    } on ProviderSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível enviar o pedido. Tente novamente.';
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              switch (_stage) {
                _Stage.details => _buildDetails(),
                _Stage.form => _buildForm(),
                _Stage.sent => _buildSent(),
              },
            ],
          ),
        ),
      ),
    );
  }

  // ── Detalhes ──────────────────────────────────────────────────────────────

  Widget _buildDetails() {
    final p = widget.provider;
    final bio = p.bio?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Avatar(provider: p),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamilyTitle,
                      fontSize: 21,
                      color: AppColors.sheetTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _CategoryChip(
                    name: p.categoryName,
                    icon: widget.category?.icon,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.highlight,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.ratingLabel,
                        style: const TextStyle(
                          color: AppColors.sheetTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '·',
                        style: TextStyle(color: AppColors.sheetTextSecondary),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          p.reviewsLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.sheetTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.payments_outlined,
                caption: 'Faixa de preço',
                value: p.priceRangeLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.schedule_rounded,
                caption: 'Tempo de resposta',
                value: p.responseLabel,
              ),
            ),
          ],
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            bio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.sheetTextSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'Solicitar',
          onPressed: () => setState(() => _stage = _Stage.form),
        ),
      ],
    );
  }

  // ── Descrição do pedido ──────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Descreva o serviço',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 21,
            color: AppColors.sheetTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'O pedido segue direto para ${widget.provider.fullName}.',
          style: const TextStyle(
            color: AppColors.sheetTextSecondary,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('request_description_field'),
          controller: _description,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Ex.: torneira da cozinha a pingar, preciso de orçamento',
            hintStyle: const TextStyle(color: AppColors.sheetTextSecondary),
            counterStyle: const TextStyle(color: AppColors.sheetTextSecondary),
            filled: true,
            fillColor: AppColors.sheetSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF6B6B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _PrimaryButton(
          label: 'Enviar pedido',
          loading: _sending,
          onPressed: _canSend ? _send : null,
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _sending
              ? null
              : () => setState(() {
                  _stage = _Stage.details;
                  _error = null;
                }),
          child: const Text(
            'Voltar',
            style: TextStyle(color: AppColors.sheetTextSecondary),
          ),
        ),
      ],
    );
  }

  // ── Confirmação ──────────────────────────────────────────────────────────

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.highlight,
          size: 56,
        ),
        const SizedBox(height: 12),
        Text(
          'Pedido enviado',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 22,
            color: AppColors.sheetTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enviámos o seu pedido a ${widget.provider.fullName}. Assim que '
          'responder com uma proposta, avisamos. Pode acompanhar o estado em '
          '"Os meus pedidos".',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.sheetTextSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'Ver o meu pedido',
          onPressed: () => widget.onViewRequest(_requestId!),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.provider});

  final ProviderSearchResult provider;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
      ),
      child: Text(
        provider.initials,
        style: TextStyle(
          fontFamily: AppTheme.fontFamilyTitle,
          fontSize: 24,
          color: AppColors.onPrimary,
        ),
      ),
    );
    final url = provider.avatarUrl;
    if (url == null || url.trim().isEmpty) return initials;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initials,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name, this.icon});

  final String name;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.highlight.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.highlight),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.highlight,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.caption,
    required this.value,
  });

  final IconData icon;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.highlight),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  caption,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.sheetTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.sheetTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.highlight.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyTitle,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
