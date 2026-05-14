import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const TripBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _items = [
    (icon: Icons.local_taxi_rounded, label: 'Viagens'),
    (icon: Icons.work_rounded, label: 'Serviços'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_items.length * 2 - 1, (i) {
            if (i.isOdd) return const SizedBox(width: 20);
            final index = i ~/ 2;
            return _NavItem(
              icon: _items[index].icon,
              label: _items[index].label,
              isSelected: selectedIndex == index,
              onTap: () => onItemSelected(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.highlight
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFF8E8E8E),
                size: 22,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
