import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/driver_candidate.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverSelectionPanel extends StatefulWidget {
  final List<DriverCandidate> candidates;
  final ValueChanged<DriverCandidate> onDriverAccepted;
  final void Function(DriverCandidate candidate, String? reason)?
  onDriverRejected;

  const DriverSelectionPanel({
    super.key,
    required this.candidates,
    required this.onDriverAccepted,
    this.onDriverRejected,
  });

  @override
  State<DriverSelectionPanel> createState() => _DriverSelectionPanelState();
}

class _DriverSelectionPanelState extends State<DriverSelectionPanel> {
  final _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showDriverProfile(DriverCandidate candidate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: _DriverProfileSheet(
          candidate: candidate,
          onAccept: () {
            Navigator.of(context).pop();
            widget.onDriverAccepted(candidate);
          },
          onReject: () {
            Navigator.of(context).pop();
            _confirmReject(candidate);
          },
        ),
      ),
    );
  }

  Future<void> _confirmReject(DriverCandidate candidate) async {
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar motorista'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Motivo do cancelamento (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    widget.onDriverRejected?.call(candidate, reason.isEmpty ? null : reason);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.candidates;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (candidates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
          children: [
            _buildGrabber(),
            const SizedBox(height: 32),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 30,
                color: AppColors.highlight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buscando motoristas...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'O admin está analisando as propostas',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
        children: [
          _buildGrabber(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROPOSTAS RECEBIDAS',
                        style: TextStyle(
                          color: Color(0xFF9A7200),
                          fontSize: 10.5,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Escolha seu motorista',
                        style: TextStyle(
                          fontFamily: 'OutfitBlack',
                          fontSize: 23,
                          color: Color(0xFF1E1D1B),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${candidates.length} ${candidates.length == 1 ? 'proposta' : 'propostas'}',
                  style: const TextStyle(
                    color: Color(0xFF7D786E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 316,
            child: PageView.builder(
              controller: _pageController,
              itemCount: candidates.length,
              itemBuilder: (ctx, i) => _DriverCard(
                candidate: candidates[i],
                onSeeMore: () => _showDriverProfile(candidates[i]),
                onAccept: () => widget.onDriverAccepted(candidates[i]),
              ),
            ),
          ),
          if (candidates.length > 1) ...[
            const SizedBox(height: 12),
            _buildDots(candidates.length),
          ],
          SizedBox(height: bottomPadding + 16),
        ],
      ),
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppColors.highlight : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

class _DriverReview {
  final double rating;
  final String comment;
  final String raterName;

  const _DriverReview({
    required this.rating,
    required this.comment,
    required this.raterName,
  });

  factory _DriverReview.fromJson(Map<String, dynamic> json) {
    final rater = json['rater'] as Map<String, dynamic>?;
    return _DriverReview(
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
      raterName: rater?['full_name'] as String? ?? 'Passageiro',
    );
  }
}

class _DriverReviewTile extends StatelessWidget {
  final _DriverReview review;

  const _DriverReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '★ ${review.rating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.highlight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.raterName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverCandidate candidate;
  final VoidCallback onSeeMore;
  final VoidCallback onAccept;

  const _DriverCard({
    required this.candidate,
    required this.onSeeMore,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final price = candidate.offeredPrice == null
        ? 'Valor a combinar'
        : 'R\$ ${candidate.offeredPrice!.toStringAsFixed(2).replaceAll('.', ',')}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF171714), Color(0xFF2C2922)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.highlight, Color(0xFFFF8A00)],
                    ),
                  ),
                  child: _driverAvatar(
                    67,
                    candidate.initials,
                    candidate.avatarUrl,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.driverName,
                        style: const TextStyle(
                          fontFamily: 'OutfitBlack',
                          fontSize: 20,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      if (candidate.vehicleSummary != null)
                        Text(
                          candidate.vehicleSummary!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB8B4AA),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (candidate.vehiclePlate != null) ...[
                        const SizedBox(height: 6),
                        _PlateBadge(plate: candidate.vehiclePlate!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(child: _VerifiedBadge()),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'VALOR PROPOSTO',
                      style: TextStyle(
                        color: Color(0xFF9F9B91),
                        fontSize: 8.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.highlight,
                        fontFamily: 'OutfitBlack',
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: GestureDetector(
                onTap: onSeeMore,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Ver perfil completo',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD7D2C7),
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onAccept,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.highlight.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Escolher motorista',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF28220F),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final double price;
  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'R\$ ${price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF22C55E),
        ),
      ),
    );
  }
}

class _PlateBadge extends StatelessWidget {
  final String plate;
  const _PlateBadge({required this.plate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        plate,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF555555),
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.22),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF22C55E)),
          SizedBox(width: 6),
          Text(
            'Perfil verificado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _driverAvatar(double size, String initials, String? avatarUrl) {
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: NetworkImage(avatarUrl),
      backgroundColor: AppColors.highlight.withValues(alpha: 0.15),
      onBackgroundImageError: (_, _) {},
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
        initials,
        style: TextStyle(
          fontSize: size * 0.37,
          fontWeight: FontWeight.w700,
          color: AppColors.highlight,
        ),
      ),
    ),
  );
}

class _DriverProfileSheet extends StatelessWidget {
  final DriverCandidate candidate;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _DriverProfileSheet({
    required this.candidate,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9F9F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildTopHandle(context),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 20),
                      const _VerifiedBadge(),
                      const SizedBox(height: 20),
                      _buildPhotoGrid(),
                      if (candidate.photoUrls.isNotEmpty)
                        const SizedBox(height: 20),
                      if (candidate.vehicleSummary != null ||
                          candidate.vehiclePlate != null ||
                          candidate.vehicleColor != null)
                        _buildVehicleCard(),
                      const SizedBox(height: 20),
                      _buildReviewsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Future<List<_DriverReview>> _loadPublicReviews() async {
    final supabase = Supabase.instance.client;
    final driverProfile = await supabase
        .from('driver_profiles')
        .select('provider_profiles(user_id)')
        .eq('id', candidate.driverProfileId)
        .maybeSingle();
    final providerProfile = _firstRelation<Map<String, dynamic>>(
      driverProfile?['provider_profiles'],
    );
    final userId = providerProfile?['user_id'] as String?;
    if (userId == null) return [];

    final rows = await supabase
        .from('ratings')
        .select('rating, comment, created_at, rater:users!rater_id(full_name)')
        .eq('rated_id', userId)
        .gte('rating', 4)
        .not('comment', 'is', null)
        .order('created_at', ascending: false)
        .limit(6);

    return (rows as List)
        .map((row) => _DriverReview.fromJson(row as Map<String, dynamic>))
        .where((review) => review.comment.trim().isNotEmpty)
        .toList();
  }

  T? _firstRelation<T>(Object? value) {
    if (value is T) return value;
    if (value is List && value.isNotEmpty && value.first is T) {
      return value.first as T;
    }
    return null;
  }

  Widget _buildTopHandle(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: Container(
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Center(
      child: Column(
        children: [
          _driverAvatar(88, candidate.initials, candidate.avatarUrl),
          const SizedBox(height: 14),
          Text(
            candidate.driverName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          if (candidate.offeredPrice != null)
            _PriceBadge(price: candidate.offeredPrice!),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  size: 20,
                  color: AppColors.highlight,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Veículo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (candidate.vehicleSummary != null)
            _sheetInfoRow(
              Icons.info_outline_rounded,
              candidate.vehicleSummary!,
            ),
          if (candidate.vehicleColor != null) ...[
            const SizedBox(height: 10),
            _sheetInfoRow(Icons.palette_outlined, candidate.vehicleColor!),
          ],
          if (candidate.vehiclePlate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: Color(0xFF999999),
                ),
                const SizedBox(width: 10),
                _PlateBadge(plate: candidate.vehiclePlate!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final photoUrls = _gridPhotoUrls();
    if (photoUrls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos do motorista e do carro',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: photoUrls.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              photoUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _gridPhotoUrls() {
    final urls = <String>[];
    final seen = <String>{};
    void add(String? url) {
      final normalized = url?.trim();
      if (normalized == null || normalized.isEmpty) return;
      if (seen.add(normalized)) urls.add(normalized);
    }

    add(candidate.avatarUrl);
    for (final url in candidate.photoUrls) {
      add(url);
    }
    return urls;
  }

  Widget _buildReviewsSection() {
    return FutureBuilder<List<_DriverReview>>(
      future: _loadPublicReviews(),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <_DriverReview>[];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Avaliações de passageiros',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (reviews.isEmpty)
                const Text(
                  'Ainda não há comentários públicos 4 ou 5 estrelas.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                )
              else
                ...reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DriverReviewTile(review: review),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF999999)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Selecionar motorista',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Recusar motorista',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
