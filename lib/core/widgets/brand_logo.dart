import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_brand.dart';

/// Logo horizontal da marca. Versão branca sobre fundo escuro, escura sobre
/// fundo claro.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.onDark, this.width});

  final bool onDark;
  final double? width;

  static const String whiteAsset = 'assets/brand/logo-horizontal-white.png';
  static const String darkAsset = 'assets/brand/logo-horizontal-dark.png';

  /// Só o "S" da marca, fundo transparente.
  static const String iconAsset = 'assets/brand/logo-icon.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onDark ? whiteAsset : darkAsset,
      width: width,
      fit: BoxFit.contain,
      semanticLabel: AppBrand.name,
    );
  }
}
