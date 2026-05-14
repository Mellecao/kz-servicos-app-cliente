import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/category_grid.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<ServiceCategoriesCubit>().state;
    if (state is! ServiceCategoriesLoaded) {
      context.read<ServiceCategoriesCubit>().loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Escolha a categoria',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ServiceCategoriesCubit, ServiceCategoriesState>(
        builder: (context, state) {
          if (state is ServiceCategoriesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.highlight,
              ),
            );
          }
          if (state is ServiceCategoriesError) {
            return _ErrorView(
              onRetry: () =>
                  context.read<ServiceCategoriesCubit>().loadCategories(),
            );
          }
          if (state is ServiceCategoriesLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 40),
              child: CategoryGrid(
                categories: state.categories,
                onCategorySelected: (category) {
                  context.push(
                    '/services/request-form',
                    extra: category,
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar categorias',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.highlight,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
