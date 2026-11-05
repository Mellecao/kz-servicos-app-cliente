import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart';

class PaymentMethodPanel extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  final VoidCallback onBack;
  final String initialMethod;

  const PaymentMethodPanel({
    super.key,
    required this.onConfirm,
    required this.onBack,
    this.initialMethod = 'cash',
  });

  @override
  State<PaymentMethodPanel> createState() => _PaymentMethodPanelState();
}

class _PaymentMethodPanelState extends State<PaymentMethodPanel> {
  static const _options = [
    ('cash', 'Numerário', Icons.payments_rounded),
    ('debit', 'Multicaixa / cartão de débito', Icons.credit_card_rounded),
    ('credit', 'Cartão de crédito', Icons.credit_score_rounded),
  ];

  late String _selected = widget.initialMethod;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Pagamento',
      onBack: widget.onBack,
      confirmLabel: 'Pedir viagem',
      onConfirm: () => widget.onConfirm(_selected),
      child: Column(
        children: [for (final option in _options) _buildOption(option)],
      ),
    );
  }

  Widget _buildOption((String, String, IconData) option) {
    final (value, label, icon) = option;
    final selected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.highlight.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.highlight
                : AppColors.sheetTextSecondary,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.sheetTextPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.sheetTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? AppColors.highlight
                  : AppColors.sheetTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
