import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/products/domain/cart.dart';

/// Stepper `− n +`. Com `quantity == 0` mostra só o botão "+" (Adicionar).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.allowZero = true,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  /// No carrinho, o "−" em 1 remove a linha (0). Mantém-se `true`.
  final bool allowZero;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return SizedBox(
        width: 40,
        height: 40,
        child: IconButton.filled(
          key: const Key('stepper_add'),
          tooltip: 'Adicionar',
          onPressed: () => onChanged(1),
          icon: const Icon(Icons.add_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.highlight,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.highlight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('stepper_minus'),
            tooltip: 'Menos',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity - 1),
            icon: Icon(
              quantity == 1 && allowZero
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              color: AppColors.highlight,
              size: 20,
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.sheetTextPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            key: const Key('stepper_plus'),
            tooltip: 'Mais',
            visualDensity: VisualDensity.compact,
            onPressed: quantity >= kMaxQuantityPerProduct
                ? null
                : () => onChanged(quantity + 1),
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.highlight,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
