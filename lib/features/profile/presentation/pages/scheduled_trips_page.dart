import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/scheduled_trip_widget.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_details_sheet.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_state.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';

class ScheduledTripsPage extends StatelessWidget {
  const ScheduledTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 8),
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ScheduledTripsCubit, ScheduledTripsState>(
                  builder: (context, state) {
                    if (state is ScheduledTripsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state is ScheduledTripsError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar viagens',
                          style: TextStyle(
                            fontFamily: 'QuasimodoSemiBold',
                            fontSize: 16,
                            color: Colors.red.shade400,
                          ),
                        ),
                      );
                    }
                    final trips = state is ScheduledTripsLoaded
                        ? state.trips
                        : <ScheduledTrip>[];
                    if (trips.isEmpty) return _buildEmptyState();
                    return _buildTripsList(trips);
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 20,
            right: 20,
            child: TripBottomNav(
              selectedIndex: 2,
              onItemSelected: (index) => _onNavTap(context, index),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) {
      context.go('/trip');
    } else if (index == 2) {
      context.go('/profile');
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Viagens Agendadas',
              style: TextStyle(
                fontFamily: 'OutfitBlack',
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: Color(0xFFBDBDBD),
          ),
          SizedBox(height: 16),
          Text(
            'Nenhuma viagem agendada',
            style: TextStyle(
              fontFamily: 'QuasimodoSemiBold',
              fontSize: 16,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(List<ScheduledTrip> trips) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      itemCount: trips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return ScheduledTripWidget(
          trip: trip,
          showMapPreview: true,
          onDetailsTap: () => TripDetailsSheet.show(context, trip),
        );
      },
    );
  }
}
