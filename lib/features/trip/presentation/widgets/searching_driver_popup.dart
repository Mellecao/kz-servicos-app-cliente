import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class SearchingDriverSheet extends StatefulWidget {
  final VoidCallback onCancel;

  const SearchingDriverSheet({super.key, required this.onCancel});

  @override
  State<SearchingDriverSheet> createState() => _SearchingDriverSheetState();
}

class _SearchingDriverSheetState extends State<SearchingDriverSheet>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _RadarIcon(controller: _radarController),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buscando motoristas',
                          style: TextStyle(
                            fontFamily: 'OutfitBlack',
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aguardando disponibilidade...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancelar pedido',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

class _RadarIcon extends StatelessWidget {
  final AnimationController controller;
  const _RadarIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(progress: controller.value),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Static inner dot
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.fill,
    );

    // Three expanding rings at staggered phases
    for (int i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final radius = phase * maxRadius;
      final opacity = (1.0 - phase).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.secondary.withValues(alpha: opacity * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}
