import 'dart:math' as math;
import 'package:flutter/material.dart';

class DustParticles extends StatefulWidget {
  const DustParticles({
    required this.color,
    required this.scrollOffset,
    this.particleCount = 25,
    super.key,
  });

  final Color color;
  final double scrollOffset;
  final int particleCount;

  @override
  State<DustParticles> createState() => _DustParticlesState();
}

class _DustParticlesState extends State<DustParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final random = math.Random(42);
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2 + random.nextDouble() * 3,
        speed: 0.2 + random.nextDouble() * 0.6,
        opacity: 0.2 + random.nextDouble() * 0.4,
        phase: random.nextDouble() * 2 * math.pi,
      ),
    );
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
          painter: _DustPainter(
            particles: _particles,
            color: widget.color,
            animationValue: _controller.value,
            scrollOffset: widget.scrollOffset,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;
}

class _DustPainter extends CustomPainter {
  _DustPainter({
    required this.particles,
    required this.color,
    required this.animationValue,
    required this.scrollOffset,
  });

  final List<_Particle> particles;
  final Color color;
  final double animationValue;
  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = animationValue * 2 * math.pi;
      final parallaxX = scrollOffset * 30 * particle.speed;

      final x = ((particle.x * size.width +
                      math.sin(t * particle.speed + particle.phase) * 20 -
                      parallaxX) %
                  size.width +
              size.width) %
          size.width;

      final y = ((particle.y * size.height +
                      math.cos(t * particle.speed * 0.7 + particle.phase) *
                          15) %
                  size.height +
              size.height) %
          size.height;

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      scrollOffset != oldDelegate.scrollOffset ||
      color != oldDelegate.color;
}
