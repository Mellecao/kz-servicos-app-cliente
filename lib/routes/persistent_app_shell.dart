import 'package:flutter/material.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';

class PersistentAppShell extends StatelessWidget {
  const PersistentAppShell({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.child,
    this.scheduledCount = 0,
    this.tripsEnabled = true,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget child;
  final int scheduledCount;

  /// `false` ⇒ o primeiro item do menu é "Buscar" (busca de prestadores).
  final bool tripsEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: TripBottomNav(
              key: const ValueKey('persistent_bottom_nav'),
              selectedIndex: currentIndex,
              scheduledCount: scheduledCount,
              tripsEnabled: tripsEnabled,
              onItemSelected: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}
