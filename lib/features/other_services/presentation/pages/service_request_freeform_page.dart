import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_state.dart';
import 'package:kz_servicos_app/features/other_services/presentation/widgets/media_attachment_picker.dart';

/// Página do Subprojeto 6: cliente descreve o profissional em texto livre
/// (sem depender de categorias pré-definidas).
class ServiceRequestFreeformPage extends StatefulWidget {
  const ServiceRequestFreeformPage({super.key});

  @override
  State<ServiceRequestFreeformPage> createState() =>
      _ServiceRequestFreeformPageState();
}

class _ServiceRequestFreeformPageState
    extends State<ServiceRequestFreeformPage> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _problemController = TextEditingController();
  final _detailsController = TextEditingController();
  final _addressController = TextEditingController();
  List<String> _mediaPaths = const [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _professionController.dispose();
    _problemController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _mediaPaths = [..._mediaPaths, file.path]);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _mediaPaths = [..._mediaPaths, file.path]);
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final request = ServiceRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: null,
      categoryName: '',
      freeformProfession: _professionController.text.trim(),
      problem: _problemController.text.trim(),
      details: _detailsController.text.trim(),
      mediaPaths: _mediaPaths,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      urgency: UrgencyType.now,
      scheduledDate: null,
      status: ServiceRequestStatus.open,
      createdAt: DateTime.now(),
    );

    context.read<ServiceRequestCubit>().submit(request);
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.2)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.highlight, width: 2),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamilyBody,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
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
            'Solicitar serviço',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('De que profissional precisa?'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _professionController,
                          decoration: _inputDecoration(
                            'Ex.: eletricista, canalizador, carpinteiro...',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o profissional'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Título do problema'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _problemController,
                          decoration: _inputDecoration(
                            'Ex: Curto-circuito na cozinha',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o problema'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Detalhes do serviço'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _detailsController,
                          decoration: _inputDecoration(
                            'Conte mais detalhes sobre o serviço...',
                          ),
                          maxLines: 5,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe os detalhes'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Fotos (opcional)'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _showMediaPicker,
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Adicionar foto'),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _mediaPaths.isEmpty
                                  ? 'Nenhuma foto anexada'
                                  : '${_mediaPaths.length} foto(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        if (_mediaPaths.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          MediaAttachmentPicker(
                            onMediaChanged: (paths) =>
                                setState(() => _mediaPaths = paths),
                            initialMediaPaths: _mediaPaths,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _sectionLabel('Morada (opcional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          decoration: _inputDecoration(
                            'Rua, número, bairro...',
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.highlight,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Enviar solicitação'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is ServiceRequestSubmitting)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.highlight,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
