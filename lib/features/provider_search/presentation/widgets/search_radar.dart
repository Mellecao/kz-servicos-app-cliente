import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

/// Animação de radar a partir do cliente: ondas laranja que se expandem e o
/// texto "A procurar prestadores próximos…". Não captura toques (o mapa por
/// baixo continua utilizável).
class SearchRadar extends StatefulWidget {
  const SearchRadar({
    super.key,
    this.label = 'A procurar prestadores próximos…',
  });

  final String label;

  @override
  State<SearchRadar> createState() => _SearchRadarState();
}

class _SearchRadarState extends State<SearchRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: const Key('search_radar'),
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: const Size(340, 340),
                painter: _RadarPainter(_controller.value),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.62),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandDark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.highlight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height) / 2;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1;
      final radius = maxRadius * Curves.easeOut.transform(phase);
      final fade = 1 - phase;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppColors.highlight.withValues(alpha: 0.20 * fade),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.highlight.withValues(alpha: 0.75 * fade),
      );
    }
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(center, 6.5, Paint()..color = AppColors.highlight);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => oldDelegate.t != t;
}
