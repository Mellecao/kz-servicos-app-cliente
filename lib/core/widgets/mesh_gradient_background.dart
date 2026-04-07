import 'dart:math' as math;
import 'package:flutter/material.dart';

class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    required this.colors,
    super.key,
  });

  final List<Color> colors;

  @override
  State<MeshGradientBackground> createState() =>
      _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshGradientPainter(
            colors: widget.colors,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.colors,
    required this.animationValue,
  });

  final List<Color> colors;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final positions = _calculatePositions(size);

    for (var i = 0; i < colors.length && i < positions.length; i++) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: 0.8),
            colors[i].withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: positions[i],
            radius: size.width * 0.7,
          ),
        );
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  List<Offset> _calculatePositions(Size size) {
    final t = animationValue * 2 * math.pi;
    return [
      Offset(
        size.width * (0.3 + 0.15 * math.cos(t)),
        size.height * (0.2 + 0.1 * math.sin(t * 1.3)),
      ),
      Offset(
        size.width * (0.7 + 0.1 * math.sin(t * 0.8)),
        size.height * (0.3 + 0.15 * math.cos(t * 1.1)),
      ),
      Offset(
        size.width * (0.4 + 0.2 * math.sin(t * 0.6)),
        size.height * (0.7 + 0.1 * math.cos(t * 0.9)),
      ),
      Offset(
        size.width * (0.8 + 0.1 * math.cos(t * 1.2)),
        size.height * (0.8 + 0.1 * math.sin(t * 0.7)),
      ),
    ];
  }

  @override
  bool shouldRepaint(_MeshGradientPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      colors != oldDelegate.colors;
}
