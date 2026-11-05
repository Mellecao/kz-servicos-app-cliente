import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/core/maps/kz_map.dart';

import '../cubits/driver_selection_cubit.dart';
import '../widgets/driver_selection_content.dart';
import '../../domain/entities/available_driver.dart';

class DriverSelectionPage extends StatelessWidget {
  const DriverSelectionPage({
    super.key,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    required this.onQuotation,
  });

  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final VoidCallback onQuotation;

  @override
  Widget build(BuildContext context) {
    final map = _buildMap();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: BlocConsumer<DriverSelectionCubit, DriverSelectionState>(
        listener: (context, state) {
          if (state is DriverSelectionRequestSent) {
            context.go('/scheduled-choose-driver/awaiting/${state.tripId}');
          } else if (state is DriverSelectionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is DriverSelectionInitial) {
            context.read<DriverSelectionCubit>().load();
          }
          final drivers = state is DriverSelectionLoaded
              ? state.drivers
              : const <AvailableDriver>[];
          final sendingDriverId = state is DriverSelectionLoaded
              ? state.sendingDriverId
              : null;
          return DriverSelectionContent(
            drivers: drivers,
            sendingDriverId: sendingDriverId,
            mapBackground: map,
            onBack: () => context.pop(),
            onDriverTap: (driver) =>
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => _DriverProfilePage(driver: driver),
                  ),
                ),
            onRequest: (id) => context.read<DriverSelectionCubit>().request(id),
            onQuotation: onQuotation,
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    if (pickupLatitude == null ||
        pickupLongitude == null ||
        dropoffLatitude == null ||
        dropoffLongitude == null) {
      return const ColoredBox(color: Color(0xFFF2F3F5));
    }
    final pickup = LatLng(pickupLatitude!, pickupLongitude!);
    final dropoff = LatLng(dropoffLatitude!, dropoffLongitude!);
    final center = LatLng(
      (pickup.latitude + dropoff.latitude) / 2,
      (pickup.longitude + dropoff.longitude) / 2,
    );
    return KzMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 14),
      markers: {
        Marker(markerId: const MarkerId('pickup'), position: pickup),
        Marker(markerId: const MarkerId('dropoff'), position: dropoff),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('selection-route'),
          points: [pickup, dropoff],
          color: AppColors.highlight,
          width: 4,
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      padding: const EdgeInsets.only(bottom: 560),
    );
  }
}

class _DriverProfilePage extends StatelessWidget {
  const _DriverProfilePage({required this.driver});
  final AvailableDriver driver;

  @override
  Widget build(BuildContext context) {
    final vehicle = driver.vehicle;
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 240,
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              title: const Text('Perfil do motorista'),
              flexibleSpace: FlexibleSpaceBar(
                background: Center(
                  child: CircleAvatar(
                    radius: 64,
                    backgroundImage: driver.avatarUrl == null
                        ? null
                        : NetworkImage(driver.avatarUrl!),
                    child: driver.avatarUrl == null
                        ? Text(
                            driver.fullName.isEmpty ? '?' : driver.fullName[0],
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverList.list(
                children: [
                  Text(
                    driver.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '★ ${driver.averageRating?.toStringAsFixed(1) ?? 'Novo'} · ${driver.totalRatings} avaliações',
                    style: const TextStyle(color: AppColors.highlight),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Motorista verificado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (vehicle != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2B2B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${vehicle.brand} ${vehicle.model}\n${vehicle.color} · ${vehicle.licensePlate}',
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.7,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Fotos e avaliações',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'As fotos públicas, o veículo e as avaliações verificadas aparecem aqui quando disponíveis.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 420),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
