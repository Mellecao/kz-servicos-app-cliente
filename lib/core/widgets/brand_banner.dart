import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_brand.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/core/widgets/brand_backdrop.dart';
import 'package:kz_servicos_app/core/widgets/brand_logo.dart';

/// Banner compacto da marca (fundo escuro, "S" e duas linhas de texto).
/// Desenhado em código: substitui os banners-imagem antigos.
class BrandBanner extends StatelessWidget {
  const BrandBanner({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BrandBackdrop(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Image.asset(
              BrandLogo.iconAsset,
              height: 56,
              fit: BoxFit.contain,
              semanticLabel: AppBrand.name,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamilyTitle,
                      fontSize: 16,
                      height: 1.15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamilyBody,
                      fontSize: 12,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
