import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/mock_provider.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/provider_detail_sheet.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/provider_list_tile.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_info_card.dart';

class RequestDetailPage extends StatefulWidget {
  final ServiceRequest request;

  const RequestDetailPage({super.key, required this.request});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final ServiceRequest _request;
  late ServiceRequestStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _currentStatus = _request.status;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} às $hour:$minute';
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
          'Detalhes do pedido',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestInfoCard(request: _request, currentStatus: _currentStatus),
          const SizedBox(height: 20),
          _buildStatusContent(),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    return switch (_currentStatus) {
      ServiceRequestStatus.searchingProvider => _buildPulsingPanel(
          icon: Icons.radar,
          iconColor: const Color(0xFFEF6C00),
          title: 'Buscando um profissional disponível...',
          subtitle: 'Estamos procurando os melhores profissionais na sua região',
        ),
      ServiceRequestStatus.selectProvider => _buildSelectProviderContent(),
      ServiceRequestStatus.awaitingConfirmation => _buildPulsingPanel(
          icon: Icons.hourglass_top,
          iconColor: const Color(0xFFF9A825),
          title: 'Aguardando confirmação do prestador',
          subtitle: 'O profissional selecionado está analisando seu pedido',
        ),
      ServiceRequestStatus.scheduled => _buildScheduledContent(),
    };
  }

  Widget _buildSelectProviderContent() {
    final providers = MockProvider.samples;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione o prestador',
          style: TextStyle(
            fontFamily: AppTheme.fontFamilyTitle,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...providers.map(
          (provider) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProviderListTile(
              provider: provider,
              onTap: () => ProviderDetailSheet.show(
                context,
                provider: provider,
                onProviderSelected: () {
                  setState(() {
                    _currentStatus = ServiceRequestStatus.awaitingConfirmation;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledContent() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 72, color: Color(0xFF2E7D32)),
          const SizedBox(height: 16),
          Text(
            'Serviço agendado!',
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          if (_request.scheduledDate != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(_request.scheduledDate!),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'O prestador confirmou e o serviço está agendado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingPanel({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              final opacity = 0.5 + (_pulseController.value * 0.5);
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
