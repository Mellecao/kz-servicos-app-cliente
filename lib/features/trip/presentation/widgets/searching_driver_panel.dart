import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class SearchingDriverPanel extends StatefulWidget {
  const SearchingDriverPanel({super.key});

  @override
  State<SearchingDriverPanel> createState() => _SearchingDriverPanelState();
}

class _SearchingDriverPanelState extends State<SearchingDriverPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildRadar(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Estamos procurando um motorista disponível, '
                'assim que sua corrida for confirmada, '
                'te avisaremos aqui.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadar() {
    return SizedBox(
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // outer pulse
              Container(
                width: 60 * _pulseAnimation.value,
                height: 60 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(
                    alpha: 0.2 * (1 - _pulseAnimation.value),
                  ),
                ),
              ),
              // middle pulse
              Container(
                width: 40 * _pulseAnimation.value,
                height: 40 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(
                    alpha: 0.3 * (1 - _pulseAnimation.value),
                  ),
                ),
              ),
              // center dot
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight,
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
