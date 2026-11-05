import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class TripRatingPanel extends StatefulWidget {
  final String driverName;
  final VoidCallback onClose;
  final VoidCallback onReportProblem;
  final void Function(int rating, String comment) onSubmit;
  final String? driverAvatarUrl;

  const TripRatingPanel({
    super.key,
    required this.driverName,
    required this.onClose,
    required this.onReportProblem,
    required this.onSubmit,
    this.driverAvatarUrl,
  });

  @override
  State<TripRatingPanel> createState() => _TripRatingPanelState();
}

class _TripRatingPanelState extends State<TripRatingPanel> {
  int _selectedStars = 0;
  final TextEditingController _commentController = TextEditingController();

  String get _initials {
    final parts = widget.driverName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGrabber(),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildAvatar(),
            const SizedBox(height: 16),
            const Text(
              'Gostou da viagem?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Avalie o serviço de ${widget.driverName.split(' ').first}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            _buildStars(),
            const SizedBox(height: 20),
            if (_selectedStars > 0) ...[
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Deixe um comentário...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.highlight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => widget.onSubmit(
                    _selectedStars,
                    _commentController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enviar feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: widget.onReportProblem,
              icon: const Icon(
                Icons.report_problem_outlined,
                size: 18,
                color: Color(0xFFE74C3C),
              ),
              label: const Text(
                'Reportar problema',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE74C3C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNum = index + 1;
        return GestureDetector(
          onTap: () => setState(() => _selectedStars = starNum),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              starNum <= _selectedStars
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 44,
              color: starNum <= _selectedStars
                  ? AppColors.highlight
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAvatar() {
    const size = 64.0;
    final avatarUrl = widget.driverAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.highlight.withValues(alpha: 0.15),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.highlight.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.highlight,
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
