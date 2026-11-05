import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/available_driver.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class DriverSelectionContent extends StatefulWidget {
  const DriverSelectionContent({
    super.key,
    required this.drivers,
    required this.onBack,
    required this.onDriverTap,
    required this.onRequest,
    required this.onQuotation,
    this.sendingDriverId,
    this.mapBackground,
  });

  final List<AvailableDriver> drivers;
  final String? sendingDriverId;
  final Widget? mapBackground;
  final VoidCallback onBack;
  final ValueChanged<AvailableDriver> onDriverTap;
  final ValueChanged<String> onRequest;
  final VoidCallback onQuotation;

  @override
  State<DriverSelectionContent> createState() => _DriverSelectionContentState();
}

class _DriverSelectionContentState extends State<DriverSelectionContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AvailableDriver> get _visibleDrivers {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.drivers;
    return widget.drivers.where((driver) {
      return driver.fullName.toLowerCase().contains(query) ||
          driver.driverProfileId.toLowerCase().contains(query) ||
          _categoryFor(driver).toLowerCase().contains(query);
    }).toList();
  }

  String _categoryFor(AvailableDriver driver) {
    final rating = driver.averageRating ?? 0;
    return rating >= 4.7 ? 'Luxo' : 'Popular';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.mapBackground ?? const ColoredBox(color: Color(0xFFF2F3F5)),
        PointerInterceptor(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              key: const Key('driver_selection_sheet'),
              height: screenHeight * .72,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.sheetBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  _header(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _searchField(),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _driverList(),
                  ),
                  const Spacer(),
                  Transform.translate(
                    offset: const Offset(0, -65),
                    child: Column(
                      key: const Key('driver_selection_final_actions'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 39,
                          child: Center(
                            child: TextButton(
                              onPressed: () => setState(() => _query = ''),
                              child: const Text(
                                'Ver todos...',
                                style: TextStyle(
                                  color: AppColors.sheetTextPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _quotationAction(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 99),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('driver_selection_back'),
              onPressed: widget.onBack,
              padding: const EdgeInsets.only(left: 18),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Text(
            'Selecionar Motorista',
            style: TextStyle(
              color: AppColors.sheetTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      key: const Key('driver_search'),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF414141),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        decoration: InputDecoration(
          hintText: 'Pesquisar motorista por nome ou tag',
          hintStyle: const TextStyle(color: Color(0xFF858585), fontSize: 10),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _driverList() {
    final drivers = _visibleDrivers.take(4).toList();
    return Container(
      key: const Key('driver_list_card'),
      height: 285,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: drivers.isEmpty
          ? const Center(
              child: Text(
                'Nenhum motorista encontrado.',
                style: TextStyle(color: AppColors.sheetTextSecondary),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < drivers.length; index++) ...[
                  Expanded(
                    child: _DriverSelectionRow(
                      driver: drivers[index],
                      category: _categoryFor(drivers[index]),
                      isWaiting:
                          widget.sendingDriverId ==
                          drivers[index].driverProfileId,
                      onTap: () => widget.onDriverTap(drivers[index]),
                      onRequest: () =>
                          widget.onRequest(drivers[index].driverProfileId),
                    ),
                  ),
                  if (index != drivers.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFF383838),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _quotationAction() {
    return Container(
      key: const Key('quotation_action'),
      height: 69,
      decoration: BoxDecoration(
        color: AppColors.sheetSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              key: const Key('quotation_button'),
              onPressed: widget.onQuotation,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.highlight,
                foregroundColor: AppColors.onPrimary,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Cotação',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Deixe que a nossa equipa escolha o melhor motorista.',
                style: TextStyle(
                  color: AppColors.sheetTextSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverSelectionRow extends StatelessWidget {
  const _DriverSelectionRow({
    required this.driver,
    required this.category,
    required this.isWaiting,
    required this.onTap,
    required this.onRequest,
  });

  final AvailableDriver driver;
  final String category;
  final bool isWaiting;
  final VoidCallback onTap;
  final VoidCallback onRequest;

  String get _displayId {
    final digits = driver.driverProfileId.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isNotEmpty) {
      return digits.length > 4 ? digits.substring(0, 4) : digits;
    }
    return driver.driverProfileId.length > 4
        ? driver.driverProfileId.substring(0, 4)
        : driver.driverProfileId;
  }

  @override
  Widget build(BuildContext context) {
    final initial = driver.fullName.isEmpty
        ? '?'
        : driver.fullName[0].toUpperCase();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF414141),
              backgroundImage: driver.avatarUrl == null
                  ? null
                  : NetworkImage(driver.avatarUrl!),
              child: driver.avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.sheetTextSecondary,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayId,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    driver.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.sheetTextPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categoria',
                    style: TextStyle(color: Color(0xFF777777), fontSize: 8),
                  ),
                  Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.sheetTextPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 98,
              height: 29,
              child: ElevatedButton(
                onPressed: isWaiting ? null : onRequest,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFF5A96EA),
                  disabledForegroundColor: Colors.white,
                  backgroundColor: AppColors.highlight,
                  foregroundColor: AppColors.onPrimary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  isWaiting ? 'A aguardar\naceitação do motorista' : 'Solicitar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isWaiting ? 8 : 12, height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
