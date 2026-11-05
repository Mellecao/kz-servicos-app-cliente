import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_detail_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_info_card.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/request_status_badge.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/service_progress_timeline.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/service_provider_card.dart';

/// Detalhe do pedido de serviço. Dados reais e em tempo real, fornecidos pelo
/// [ServiceRequestDetailCubit] (o `BlocProvider` é criado na rota).
class RequestDetailPage extends StatefulWidget {
  const RequestDetailPage({super.key});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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

  void _showMessage(String text, {required bool error}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? const Color(0xFFB3261E) : const Color(0xFF2E7D32),
          content: Text(text),
        ),
      );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text(
          'Só é possível cancelar antes de o serviço começar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Manter pedido'),
          ),
          TextButton(
            key: const Key('service_cancel_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Cancelar pedido',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ServiceRequestDetailCubit>().cancel();
    }
  }

  Future<void> _openChat() async {
    final room = await context.read<ServiceRequestDetailCubit>().openChat();
    if (room != null && mounted) context.push('/chat/$room');
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
      body: BlocConsumer<ServiceRequestDetailCubit, ServiceRequestDetailState>(
        listenWhen: (a, b) =>
            (b.actionError != null && b.actionError != a.actionError) ||
            (b.notice != null && b.notice != a.notice),
        listener: (context, state) {
          if (state.actionError != null) {
            _showMessage(state.actionError!, error: true);
          } else if (state.notice != null) {
            _showMessage(state.notice!, error: false);
          }
        },
        builder: (context, state) {
          final request = state.request;
          if (request == null) {
            if (state.status == RequestDetailStatus.error) {
              return _Message(
                icon: Icons.error_outline_rounded,
                title: 'Erro ao carregar o pedido',
                subtitle: state.message,
                actionLabel: 'Tentar novamente',
                onAction: () => context.read<ServiceRequestDetailCubit>().load(),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: AppColors.highlight),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RequestInfoCard(request: request, currentStatus: request.status),
              const SizedBox(height: 20),
              ..._statusContent(request, state),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _statusContent(ServiceRequest request, ServiceRequestDetailState state) {
    final status = request.status;
    final provider = request.provider;
    final widgets = <Widget>[];

    switch (status) {
      case ServiceRequestStatus.open:
        widgets.add(_pulsingPanel(
          icon: Icons.send_rounded,
          color: status.color,
          title: 'Pedido enviado',
          subtitle: 'A nossa equipa vai analisar o seu pedido dentro de momentos.',
        ));
      case ServiceRequestStatus.underReview:
        widgets.add(_pulsingPanel(
          icon: Icons.fact_check_outlined,
          color: status.color,
          title: 'A analisar o seu pedido',
          subtitle: 'A equipa da Só Serviços está a verificar os detalhes.',
        ));
      case ServiceRequestStatus.searchingProvider:
        widgets.add(_pulsingPanel(
          icon: Icons.radar,
          color: status.color,
          title: 'À procura de um profissional disponível...',
          subtitle: 'Estamos à procura dos melhores profissionais na sua zona.',
        ));
      case ServiceRequestStatus.reviewRejected:
        widgets.add(_banner(
          icon: Icons.block_rounded,
          color: status.color,
          title: 'Pedido recusado',
          subtitle: 'Pode fazer um novo pedido com mais detalhes.',
        ));
      case ServiceRequestStatus.cancelled:
        widgets.add(_banner(
          icon: Icons.cancel_outlined,
          color: status.color,
          title: 'Pedido cancelado',
          subtitle: 'Este pedido foi cancelado.',
        ));
      case ServiceRequestStatus.awaitingClientConfirmation:
        if (provider != null) {
          widgets.add(const _SectionTitle('O prestador escolhido'));
          widgets.add(ServiceProviderCard(
            provider: provider,
            finalPrice: request.finalPrice,
          ));
        }
        widgets.add(const SizedBox(height: 16));
        widgets.add(_primaryButton(
          key: const Key('service_accept'),
          label: 'Aceitar',
          busy: state.busy,
          onPressed: () async {
            await context.read<ServiceRequestDetailCubit>().accept();
          },
        ));
      case ServiceRequestStatus.awaitingProviderConfirmation:
        widgets.add(_pulsingPanel(
          icon: Icons.hourglass_top,
          color: status.color,
          title: 'A aguardar confirmação do prestador',
          subtitle: 'Aceitou o prestador. Avisamos assim que ele confirmar.',
        ));
        if (provider != null) {
          widgets.add(ServiceProviderCard(
            provider: provider,
            finalPrice: request.finalPrice,
          ));
        }
      case ServiceRequestStatus.assigned:
      case ServiceRequestStatus.inProgress:
      case ServiceRequestStatus.finished:
        widgets.add(ServiceProgressTimeline(status: status));
        widgets.add(const SizedBox(height: 12));
        if (provider != null) {
          widgets.add(ServiceProviderCard(
            provider: provider,
            finalPrice: request.finalPrice,
          ));
        }
        widgets.add(const SizedBox(height: 4));
        widgets.add(Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              switch (status) {
                ServiceRequestStatus.assigned =>
                  'O prestador confirmou. Combine os detalhes pelo chat.',
                ServiceRequestStatus.inProgress => 'O serviço está em curso.',
                _ => 'Serviço concluído. Obrigado por escolher a Só Serviços!',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ));
    }

    if (status.hasChat && provider != null) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          key: const Key('service_open_chat'),
          onPressed: state.busy ? null : _openChat,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Abrir conversa com o prestador'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ));
    }

    if (status.canCancel) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(SizedBox(
        height: 48,
        child: OutlinedButton(
          key: const Key('service_cancel'),
          onPressed: state.busy ? null : _confirmCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            side: const BorderSide(color: Color(0xFFD32F2F)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Cancelar pedido'),
        ),
      ));
    }
    widgets.add(const SizedBox(height: 24));
    return widgets;
  }

  Widget _primaryButton({
    required Key key,
    required String label,
    required bool busy,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: key,
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.highlight.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _banner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamilyTitle,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulsingPanel({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
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
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 40, color: color),
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

extension on ServiceRequestStatus {
  Color get color => RequestStatusBadge.styleFor(this).color;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamilyTitle,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(
              fontFamily: AppTheme.fontFamilyTitle,
              fontSize: 16,
              color: AppColors.textPrimary,
            )),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.highlight,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
