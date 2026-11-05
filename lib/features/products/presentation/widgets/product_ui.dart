import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/core/utils/kz_format.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';

/// Ícone Material por produto (o catálogo não tem fotografias).
IconData productIcon(String slug) {
  if (slug.startsWith('agua-cisterna')) return Icons.local_shipping_rounded;
  if (slug.startsWith('gelo')) return Icons.ac_unit_rounded;
  if (slug.startsWith('agua')) return Icons.water_drop_rounded;
  if (slug.startsWith('botija')) return Icons.propane_tank_rounded;
  return Icons.shopping_bag_rounded;
}

/// `dd/MM/yyyy HH:mm` em hora de Luanda (UTC+1, sem hora de verão).
String formatOrderDate(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date.toUtc().add(const Duration(hours: 1)));

/// Cor do estado do pedido.
Color orderStatusColor(ProductOrderStatus status) => switch (status) {
  ProductOrderStatus.pending => const Color(0xFFF9A825),
  ProductOrderStatus.confirmed => const Color(0xFF42A5F5),
  ProductOrderStatus.outForDelivery => AppColors.highlight,
  ProductOrderStatus.delivered => const Color(0xFF66BB6A),
  ProductOrderStatus.cancelled => const Color(0xFFEF5350),
};

IconData orderStatusIcon(ProductOrderStatus status) => switch (status) {
  ProductOrderStatus.pending => Icons.hourglass_top_rounded,
  ProductOrderStatus.confirmed => Icons.check_circle_outline_rounded,
  ProductOrderStatus.outForDelivery => Icons.local_shipping_rounded,
  ProductOrderStatus.delivered => Icons.task_alt_rounded,
  ProductOrderStatus.cancelled => Icons.cancel_outlined,
};

InputDecoration productInputDecoration(
  String label, {
  String? hint,
  String? prefixText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.sheetSurface,
    labelStyle: const TextStyle(color: AppColors.sheetTextSecondary),
    hintStyle: const TextStyle(color: AppColors.sheetTextSecondary),
    prefixStyle: const TextStyle(color: AppColors.sheetTextPrimary),
    border: border(Colors.transparent),
    enabledBorder: border(Colors.transparent),
    focusedBorder: border(AppColors.highlight),
    errorBorder: border(const Color(0xFFEF5350)),
    focusedErrorBorder: border(const Color(0xFFEF5350)),
  );
}

/// Cabeçalho das páginas de produtos (voltar + título + ação opcional).
class ProductsHeader extends StatelessWidget {
  const ProductsHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.sheetTextPrimary,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamilyTitle,
                  fontSize: 20,
                  color: AppColors.sheetTextPrimary,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Estado vazio / erro com ação opcional.
class ProductsMessageView extends StatelessWidget {
  const ProductsMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor ?? AppColors.sheetTextSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamilyTitle,
                fontSize: 16,
                color: AppColors.sheetTextPrimary,
              ),
            ),
            if (subtitle case final sub?) ...[
              const SizedBox(height: 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.sheetTextSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.highlight,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
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
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.highlight.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

/// Subtotal + taxa de entrega + total. `deliveryFee == null` → taxa por
/// confirmar (o servidor aplica a taxa certa ao criar o pedido).
class OrderTotals extends StatelessWidget {
  const OrderTotals({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
  });

  final double subtotal;
  final double? deliveryFee;

  @override
  Widget build(BuildContext context) {
    final fee = deliveryFee;
    return Column(
      children: [
        _row('Subtotal', formatKz(subtotal)),
        const SizedBox(height: 6),
        _row('Taxa de entrega', fee == null ? 'A confirmar' : formatKz(fee)),
        const Divider(height: 20, color: AppColors.sheetSurface),
        _row(
          fee == null ? 'Total (sem taxa)' : 'Total',
          formatKz(subtotal + (fee ?? 0)),
          bold: true,
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 17 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.sheetTextPrimary : AppColors.sheetTextSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: bold ? AppColors.highlight : AppColors.sheetTextPrimary,
          ),
        ),
      ],
    );
  }
}
