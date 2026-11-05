import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';

/// Atalho para "Buscar prestadores" na página de serviços. Só aparece com as
/// viagens ligadas (`trips_enabled=true`): com elas desligadas a busca já é a
/// primeira tela.
class ProviderSearchEntryCard extends StatelessWidget {
  const ProviderSearchEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: const Key('provider_search_entry'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/provider-search'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: AppColors.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buscar prestadores',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamilyTitle,
                          fontSize: 17,
                          color: AppColors.sheetTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Veja no mapa os profissionais perto de si',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.sheetTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.sheetTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
