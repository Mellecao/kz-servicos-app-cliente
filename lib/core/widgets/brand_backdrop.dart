import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

/// Fundo escuro da marca com dois brilhos suaves (rosa e laranja). Substitui as
/// ilustrações antigas: tudo é desenhado em código, sem imagens.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.brandDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -150,
            left: -130,
            child: _Glow(color: AppColors.pink, size: 400),
          ),
          const Positioned(
            bottom: -170,
            right: -150,
            child: _Glow(color: AppColors.highlight, size: 440),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: .34), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
