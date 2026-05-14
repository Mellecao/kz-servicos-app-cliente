import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';

class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    super.key,
  });

  final List<ServiceCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'Todos',
              isActive: selectedCategoryId == null,
              onTap: () => onSelected(null),
            );
          }
          final category = categories[index - 1];
          return _FilterChip(
            label: category.name,
            isActive: selectedCategoryId == category.id,
            color: category.color,
            onTap: () => onSelected(
              selectedCategoryId == category.id ? null : category.id,
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.highlight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyBody,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? activeColor : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
