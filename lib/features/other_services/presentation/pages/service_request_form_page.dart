import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/service_request_form.dart';

class ServiceRequestFormPage extends StatelessWidget {
  const ServiceRequestFormPage({
    required this.category,
    super.key,
  });

  final ServiceCategory category;

  void _onFormSubmit(BuildContext context, ServiceRequest request) {
    context.read<ServiceRequestCubit>().submit(request);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServiceRequestCubit, ServiceRequestState>(
      listener: (context, state) {
        if (state is ServiceRequestSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido enviado com sucesso!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          context.read<ServiceRequestCubit>().reset();
          context.go('/services/requests');
        } else if (state is ServiceRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Solicitar ${category.name}',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ServiceRequestCubit, ServiceRequestState>(
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: ServiceRequestForm(
                    category: category,
                    onSubmit: (request) => _onFormSubmit(context, request),
                  ),
                ),
                if (state is ServiceRequestSubmitting)
                  const _LoadingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.highlight),
      ),
    );
  }
}
