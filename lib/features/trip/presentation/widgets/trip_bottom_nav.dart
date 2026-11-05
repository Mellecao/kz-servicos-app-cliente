import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int scheduledCount;

  const TripBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.scheduledCount = 0,
  });

  static const _items = [
    (icon: Icons.local_taxi_rounded, label: 'Viagens'),
    (icon: Icons.calendar_month_rounded, label: 'Agendamentos'),
    (icon: Icons.work_rounded, label: 'Serviços'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          return Expanded(
            child: _NavItem(
              icon: _items[i].icon,
              label: _items[i].label,
              isSelected: selectedIndex == i,
              badgeCount: i == 1 ? scheduledCount : 0,
              onTap: () => onItemSelected(i),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [],
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: isSelected ? 1.15 : 0.9,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      icon,
                      color: isSelected ? AppColors.highlight : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
