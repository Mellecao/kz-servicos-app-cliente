import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_list_tile.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ServiceRequestsListCubit>().load();
  }

  void _onNavItemSelected(int index) {
    switch (index) {
      case 0:
        context.go('/trip');
      case 1:
        context.go('/services');
      case 2:
        context.go('/profile');
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
          'Meus Pedidos',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/services/new'),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Contratar Novo Serviço',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamilyTitle,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.highlight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<ServiceRequestsListCubit,
                    ServiceRequestsListState>(
                  builder: (context, state) {
                    if (state is ServiceRequestsListLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.highlight,
                        ),
                      );
                    }
                    if (state is ServiceRequestsListError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .read<ServiceRequestsListCubit>()
                                  .load(),
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
                    if (state is ServiceRequestsListLoaded) {
                      if (state.requests.isEmpty) {
                        return const _EmptyState();
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: state.requests.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = state.requests[index];
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
              ),
            ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum pedido realizado',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
