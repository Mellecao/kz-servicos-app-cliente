import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/data/models/mock_driver.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverSelectionPanel extends StatefulWidget {
  final ValueChanged<MockDriver> onDriverAccepted;

  const DriverSelectionPanel({
    super.key,
    required this.onDriverAccepted,
  });

  @override
  State<DriverSelectionPanel> createState() => _DriverSelectionPanelState();
}

class _DriverSelectionPanelState extends State<DriverSelectionPanel> {
  final _pageController = PageController(viewportFraction: 0.88);
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

  void _showDriverProfile(MockDriver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PointerInterceptor(
        child: _DriverProfileSheet(
          driver: driver,
          onAccept: () {
            Navigator.of(context).pop();
            widget.onDriverAccepted(driver);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drivers = MockDriver.samples;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
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
          children: [
            _buildGrabber(),
            const SizedBox(height: 8),
            const Text(
              'Motoristas disponíveis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: drivers.length,
                itemBuilder: (ctx, i) => _DriverCard(
                  driver: drivers[i],
                  onSeeMore: () => _showDriverProfile(drivers[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDots(drivers.length),
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
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppColors.highlight : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final MockDriver driver;
  final VoidCallback onSeeMore;

  const _DriverCard({required this.driver, required this.onSeeMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${driver.carModel} • ${driver.carColor}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.highlight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      driver.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onSeeMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.highlight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ver mais',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.highlight.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          driver.initials,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.highlight,
          ),
        ),
      ),
    );
  }
}

class _DriverProfileSheet extends StatelessWidget {
  final MockDriver driver;
  final VoidCallback onAccept;

  const _DriverProfileSheet({
    required this.driver,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildSection('Sobre', driver.description),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'RG',
                        driver.rg,
                      ),
                      _buildInfoRow(
                        'Data de nascimento',
                        '${driver.birthDate.day.toString().padLeft(2, '0')}/'
                            '${driver.birthDate.month.toString().padLeft(2, '0')}/'
                            '${driver.birthDate.year}',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Veículo',
                        '${driver.carModel} — ${driver.carColor}',
                      ),
                      const SizedBox(height: 12),
                      _buildCarPhotos(),
                      const SizedBox(height: 16),
                      _buildExtras(),
                      if (driver.driverNote != null &&
                          driver.driverNote!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDriverNote(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildAcceptButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: Colors.black54,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.highlight.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                driver.initials,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.highlight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            driver.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: AppColors.highlight,
              ),
              const SizedBox(width: 4),
              Text(
                driver.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarPhotos() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, i) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => Container(
          width: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.directions_car_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adicionais',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: driver.extras.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.highlight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                e,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.highlight,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDriverNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text(
                'Observação do motorista',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            driver.driverNote!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
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
            'Aceitar motorista',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
