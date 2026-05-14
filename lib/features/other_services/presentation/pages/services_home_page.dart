import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/category_filter_chips.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/new_service_button.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_list_tile.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';

class ServicesHomePage extends StatefulWidget {
  const ServicesHomePage({super.key});

  @override
  State<ServicesHomePage> createState() => _ServicesHomePageState();
}

class _ServicesHomePageState extends State<ServicesHomePage> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ServiceCategoriesCubit>().loadCategories();
    context.read<ServiceRequestsListCubit>().load();
  }

  void _onNavItemSelected(int index) {
    switch (index) {
      case 0:
        context.go('/trip');
      case 2:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                NewServiceButton(
                  onTap: () => context.push('/services/new'),
                ),
                const SizedBox(height: 20),
                BlocBuilder<ServiceCategoriesCubit, ServiceCategoriesState>(
                  builder: (context, catState) {
                    if (catState is ServiceCategoriesLoaded) {
                      return CategoryFilterChips(
                        categories: catState.categories,
                        selectedCategoryId: _selectedCategoryId,
                        onSelected: (id) {
                          setState(() => _selectedCategoryId = id);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<ServiceRequestsListCubit,
                    ServiceRequestsListState>(
                  builder: (context, state) {
                    if (state is ServiceRequestsListLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.highlight,
                          ),
                        ),
                      );
                    }
                    if (state is ServiceRequestsListError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<ServiceRequestsListCubit>()
                            .load(),
                      );
                    }
                    if (state is ServiceRequestsListLoaded) {
                      final filtered = _selectedCategoryId == null
                          ? state.requests
                          : state.requests
                              .where(
                                (r) => r.categoryId == _selectedCategoryId,
                              )
                              .toList();
                      if (filtered.isEmpty) {
                        return const _EmptyState();
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = filtered[index];
                          return RequestListTile(
                            request: request,
                            onTap: () => context.push(
                              '/services/requests/${request.id}',
                              extra: request,
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: TripBottomNav(
              selectedIndex: 1,
              onItemSelected: _onNavItemSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Center(
          child: Text(
            'Serviços',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 22,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppColors.textPrimary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum serviço solicitado',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar serviços',
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
