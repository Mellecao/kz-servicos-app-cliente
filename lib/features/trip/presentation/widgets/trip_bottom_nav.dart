import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const TripBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavItem(
            svgPath: 'assets/images/SVG/car_front_view.svg',
            label: 'Viagens',
            isSelected: selectedIndex == 0,
            onTap: () => onItemSelected(0),
          ),
          const SizedBox(width: 6),
          _NavItem(
            svgPath: 'assets/images/SVG/briefcase.svg',
            label: 'Serviços',
            isSelected: selectedIndex == 1,
            onTap: () => onItemSelected(1),
          ),
          const SizedBox(width: 6),
          _NavItem(
            svgPath: 'assets/images/SVG/avatar.svg',
            label: 'Perfil',
            isSelected: selectedIndex == 2,
            onTap: () => onItemSelected(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String svgPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.svgPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.highlight
                  : Colors.transparent,
            ),
            child: Center(
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.45,
                child: SvgPicture.asset(
                  svgPath,
                  width: 26,
                  height: 26,
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? AppColors.highlight : Colors.black45,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
