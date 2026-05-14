import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:kz_servicos_app/features/profile/data/models/mock_trip_history.dart';
import 'package:kz_servicos_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:kz_servicos_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/quick_actions_grid.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/settings_list.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_state.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _tripHistory = MockTripHistory.samples;
  final int _selectedNavIndex = 2;
  final ImagePicker _imagePicker = ImagePicker();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      final userId = authState.user.id;
      context.read<ProfileCubit>().loadStats(userId);
      context.read<ScheduledTripsCubit>().load(userId);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/trip');
      case 1:
        context.go('/services');
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Sair da conta',
          style: TextStyle(
            fontFamily: 'OutfitBlack',
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: TextStyle(
            fontFamily: 'QuasimodoSemiBold',
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().signOut();
    }
  }

  Future<void> _onEditPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Alterar Foto',
              style: TextStyle(
                fontFamily: 'OutfitBlack',
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.secondary,
                ),
              ),
              title: const Text(
                'Câmera',
                style: TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.highlight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.highlight,
                ),
              ),
              title: const Text(
                'Galeria',
                style: TextStyle(
                  fontFamily: 'QuasimodoSemiBold',
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null && mounted) {
      setState(() => _avatarPath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final userName = user?.fullName ?? '';
    final userEmail = user?.email ?? '';
    final userPhone = user?.phone;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 8),
                ProfileHeader(
                  name: userName,
                  email: userEmail,
                  phone: userPhone,
                  profileCompletion: 0.0,
                  hasNotifications: false,
                  onBackTap: () => context.go('/trip'),
                  onEditPhotoTap: _onEditPhoto,
                  avatarPath: _avatarPath,
                  avatarUrl: user?.avatarUrl,
                ),
                const SizedBox(height: 24),
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, profileState) {
                    final stats = profileState is ProfileLoaded
                        ? profileState.stats
                        : null;
                    return BlocBuilder<ScheduledTripsCubit,
                        ScheduledTripsState>(
                      builder: (context, tripsState) {
                        final scheduledCount =
                            tripsState is ScheduledTripsLoaded
                                ? tripsState.trips.length
                                : 0;
                        return QuickActionsGrid(
                          completedTrips: scheduledCount,
                          completedTripsLabel: 'agendadas',
                          requestedServices:
                              stats?.requestedServices ?? 0,
                          unreadMessages: stats?.unreadMessages ?? 0,
                          onTripsTap: () =>
                              context.push('/scheduled-trips'),
                          onMessagesTap: () =>
                              context.push('/messages'),
                          onPaymentsTap: () =>
                              context.push('/wallet'),
                          onServicesTap: () =>
                              context.push('/services'),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configurações',
                        style: TextStyle(
                          fontFamily: 'OutfitBlack',
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<ScheduledTripsCubit, ScheduledTripsState>(
                        builder: (context, tripsState) {
                          return SettingsList(
                            scheduledTrips: tripsState is ScheduledTripsLoaded
                                ? tripsState.trips
                                : [],
                            tripHistory: _tripHistory,
                            onSecurityTap: () =>
                                context.push('/security-settings'),
                            onViewAllScheduledTap: () =>
                                context.push('/scheduled-trips'),
                            onHistoryTripTap: () =>
                                context.push('/trip-history'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: Color(0xFFD32F2F),
                      ),
                      label: const Text(
                        'Sair da conta',
                        style: TextStyle(
                          fontFamily: 'QuasimodoSemiBold',
                          fontSize: 15,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: Color(0x33D32F2F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 20,
            right: 20,
            child: TripBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}
