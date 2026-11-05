import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int scheduledCount;

  /// Com as viagens desligadas (`trips_enabled=false`) o primeiro item é a
  /// busca de prestadores em vez do táxi.
  final bool tripsEnabled;

  const TripBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.scheduledCount = 0,
    this.tripsEnabled = true,
  });

  static const _tripsItem = (icon: Icons.local_taxi_rounded, label: 'Viagens');
  static const _searchItem = (icon: Icons.search_rounded, label: 'Buscar');

  /// Cada item guarda o índice do ramo do shell que abre, para que ocultar
  /// "Agendamentos" (viagens desligadas) não desloque os restantes.
  List<({int branch, IconData icon, String label})> get _items => [
    (
      branch: 0,
      icon: tripsEnabled ? _tripsItem.icon : _searchItem.icon,
      label: tripsEnabled ? _tripsItem.label : _searchItem.label,
    ),
    if (tripsEnabled)
      (
        branch: 1,
        icon: Icons.calendar_month_rounded,
        label: 'Agendamentos',
      ),
    (branch: 2, icon: Icons.work_rounded, label: 'Serviços'),
    (branch: 3, icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
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
        children: [
          for (final item in items)
            Expanded(
              child: _NavItem(
                icon: item.icon,
                label: item.label,
                isSelected: selectedIndex == item.branch,
                badgeCount: item.branch == 1 ? scheduledCount : 0,
                onTap: () => onItemSelected(item.branch),
              ),
            ),
        ],
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
