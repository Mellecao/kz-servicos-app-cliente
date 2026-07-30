import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:kz_servicos_app/features/auth/presentation/pages/login_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/chat_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/messages_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/profile_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/scheduled_trips_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/security_settings_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/trip_history_page.dart';
import 'package:kz_servicos_app/features/profile/presentation/pages/wallet_page.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/my_requests_page.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/request_detail_page.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/service_request_form_page.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/service_request_freeform_page.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/category_selection_page.dart';
import 'package:kz_servicos_app/features/other_services/presentation/pages/services_home_page.dart';
import 'package:kz_servicos_app/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/repositories/flash_trip_repository_impl.dart';
import 'package:kz_servicos_app/features/trip/data/services/active_flash_gate.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/flash_creation_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/flash_searching_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/pages/flash_details_page.dart';
import 'package:kz_servicos_app/features/trip/presentation/pages/flash_searching_page.dart';
import 'package:kz_servicos_app/features/trip/presentation/pages/trip_home_page.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/available_drivers_repository.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/pages/awaiting_driver_response_page.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/pages/price_offer_review_page.dart';

const _publicRoutes = {'/splash', '/login'};

abstract final class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: _AuthNotifier(authCubit),
      redirect: (context, state) async {
        final isLoggedIn = authCubit.state is AuthSuccess;
        final isPublic = _publicRoutes.contains(state.matchedLocation);

        if (!isLoggedIn && !isPublic) return '/login';

        if (isLoggedIn && state.matchedLocation == '/trip') {
          final gate = ActiveFlashGate(client: Supabase.instance.client);
          try {
            final target = await gate.resolveTargetPath();
            if (target != null && target != state.matchedLocation) {
              return target;
            }
          } catch (_) {
            // gate falha silenciosa — mantém rota original
          }
        }
        return null;
      },
      routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/trip',
        builder: (context, state) => const TripHomePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/scheduled-trips',
        builder: (context, state) => const ScheduledTripsPage(),
      ),
      GoRoute(
        path: '/security-settings',
        builder: (context, state) => const SecuritySettingsPage(),
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesPage(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) => ChatPage(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/trip-history',
        builder: (context, state) => const TripHistoryPage(),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicesHomePage(),
      ),
      GoRoute(
        path: '/services/new',
        builder: (context, state) => const CategorySelectionPage(),
      ),
      GoRoute(
        path: '/services/new-freeform',
        builder: (context, state) => const ServiceRequestFreeformPage(),
      ),
      GoRoute(
        path: '/services/request-form',
        builder: (context, state) {
          final category = state.extra! as ServiceCategory;
          return ServiceRequestFormPage(category: category);
        },
      ),
      GoRoute(
        path: '/services/requests',
        builder: (context, state) => const MyRequestsPage(),
      ),
      GoRoute(
        path: '/services/requests/:id',
        builder: (context, state) {
          final request = state.extra! as ServiceRequest;
          return RequestDetailPage(request: request);
        },
      ),
      GoRoute(
        path: '/flash/details',
        builder: (context, state) {
          final args = state.extra! as Map<String, String>;
          return BlocProvider(
            create: (_) => FlashCreationCubit(
              repository: FlashTripRepositoryImpl(
                client: Supabase.instance.client,
              ),
            ),
            child: FlashDetailsPage(
              pickupAddressId: args['pickup']!,
              dropoffAddressId: args['dropoff']!,
              serviceCategoryId: args['category']!,
            ),
          );
        },
      ),
      GoRoute(
        path: '/flash/searching/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return BlocProvider(
            create: (_) => FlashSearchingCubit(
              repository: FlashTripRepositoryImpl(
                client: Supabase.instance.client,
              ),
              tripId: tripId,
            ),
            child: FlashSearchingPage(tripId: tripId),
          );
        },
      ),
      GoRoute(
        path: '/scheduled-choose-driver/select',
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => DriverSelectionCubit(
              driversRepo: AvailableDriversRepository(),
              requestRepo: ScheduledDirectRequestRepository(),
              pickupAddressId: extra['pickupAddressId'] as String,
              dropoffAddressId: extra['dropoffAddressId'] as String,
              serviceCategoryId: extra['serviceCategoryId'] as String,
              passengerCount: extra['passengerCount'] as int,
              scheduledDatetime: extra['scheduledDatetime'] as DateTime,
              observation: extra['observation'] as String?,
            ),
            child: const DriverSelectionPage(),
          );
        },
      ),
      GoRoute(
        path: '/scheduled-choose-driver/awaiting/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return BlocProvider(
            create: (_) => AwaitingResponseCubit(
              tripId: tripId,
              repo: ScheduledDirectRequestRepository(),
            )..start(),
            child: const AwaitingDriverResponsePage(),
          );
        },
      ),
      GoRoute(
        path: '/scheduled-choose-driver/price-review/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return BlocProvider(
            create: (_) => AwaitingResponseCubit(
              tripId: tripId,
              repo: ScheduledDirectRequestRepository(),
            )..start(),
            child: PriceOfferReviewPage(tripId: tripId),
          );
        },
      ),
    ],
    );
  }
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
