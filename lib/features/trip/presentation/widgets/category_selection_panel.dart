import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class CategoryInfo {
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;

  const CategoryInfo({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}

const List<CategoryInfo> kCategories = [
  CategoryInfo(
    name: 'KZ STANDARD',
    subtitle: 'Conforto acessível',
    description:
        'Veículos sedan ou hatch em ótimo estado de conservação. '
        'Ideal para trajetos urbanos e viagens curtas com custo-benefício. '
        'Ar condicionado, som automotivo e motorista verificado.',
    icon: Icons.directions_car_rounded,
  ),
  CategoryInfo(
    name: 'KZ CONFORT',
    subtitle: 'Experiência premium',
    description:
        'Veículos SUV ou sedan executivo com bancos em couro e '
        'acabamento superior. Wi-Fi a bordo, água mineral e '
        'carregador de celular disponíveis. Para quem busca '
        'conforto extra na viagem.',
    icon: Icons.airline_seat_recline_extra_rounded,
  ),
  CategoryInfo(
    name: 'KZ DELUXE',
    subtitle: 'Luxo e exclusividade',
    description:
        'Veículos de luxo com motorista bilíngue e atendimento '
        'VIP. Inclui todos os benefícios do Confort com adição '
        'de snacks, revistas e atendimento personalizado. '
        'Ideal para executivos e ocasiões especiais.',
    icon: Icons.diamond_rounded,
  ),
];

class CategorySelectionPanel extends StatelessWidget {
  final ValueChanged<int> onCategorySelected;

  const CategorySelectionPanel({
    super.key,
    required this.onCategorySelected,
  });

  void _showDetails(BuildContext context, CategoryInfo category) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDetailsPopup(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione a categoria',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(kCategories.length, (i) {
            final cat = kCategories[i];
            return _CategoryCard(
              category: cat,
              onSelect: () => onCategorySelected(i),
              onDetails: () => _showDetails(context, cat),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryInfo category;
  final VoidCallback onSelect;
  final VoidCallback onDetails;

  const _CategoryCard({
    required this.category,
    required this.onSelect,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.highlight.withValues(alpha: 0.15),
                ),
                child: Icon(
                  category.icon,
                  color: AppColors.highlight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      category.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDetails,
                child: Text(
                  'Detalhes',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Selecionar categoria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDetailsPopup extends StatelessWidget {
  final CategoryInfo category;

  const _CategoryDetailsPopup({required this.category});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.highlight.withValues(alpha: 0.15),
              ),
              child: Icon(
                category.icon,
                size: 40,
                color: AppColors.highlight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
