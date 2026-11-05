import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:kz_servicos_app/core/constants/app_brand.dart';
import 'package:kz_servicos_app/core/constants/app_locale.dart';
import 'package:kz_servicos_app/core/services/notification_service.dart';
import 'package:kz_servicos_app/core/theme/app_theme.dart';
import 'package:kz_servicos_app/firebase_options.dart';
import 'package:kz_servicos_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kz_servicos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kz_servicos_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_category_repository_impl.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository_impl.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_cubit.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository.dart';
import 'package:kz_servicos_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/product_orders_cubit.dart';
import 'package:kz_servicos_app/features/products/presentation/cubit/products_cubit.dart';
import 'package:kz_servicos_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:kz_servicos_app/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:kz_servicos_app/features/trip/domain/usecases/create_trip.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/pending_confirmations_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/trip_creation_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_cubit.dart';
import 'package:kz_servicos_app/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_data.initializeTimeZones();

  await Supabase.initialize(
    url: 'https://mtsqeomctrqfyekyzapc.supabase.co',
    anonKey:
        'sb_publishable_oP6AOTWJK8zL030EUyhlOQ_WZ5NXFNm',
  );
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.instance.initialize(
      client: Supabase.instance.client,
      userId: Supabase.instance.client.auth.currentUser?.id,
    );
  }

  runApp(const KzServicosApp());
}

class KzServicosApp extends StatelessWidget {
  const KzServicosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;
    final dataSource = AuthRemoteDataSourceImpl(supabaseClient);
    final repository = AuthRepositoryImpl(dataSource);
    final signInWithEmail = SignInWithEmail(repository);
    final signUpWithEmail = SignUpWithEmail(repository);
    final authCubit = AuthCubit(
      signInWithEmail: signInWithEmail,
      signUpWithEmail: signUpWithEmail,
      repository: repository,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider(create: (_) => ProfileCubit(client: supabaseClient)),
        BlocProvider(
          create: (_) => TripCreationCubit(
            createTrip: CreateTrip(TripRepositoryImpl(client: supabaseClient)),
          ),
        ),
        BlocProvider(
          create: (_) => ScheduledTripsCubit(
            repository: TripRepositoryImpl(client: supabaseClient),
          ),
        ),
        BlocProvider(
          create: (_) => PendingConfirmationsCubit(
            repository: TripRepositoryImpl(client: supabaseClient),
          ),
        ),
        BlocProvider(
          create: (_) => ServiceCategoriesCubit(
            repository: ServiceCategoryRepositoryImpl(client: supabaseClient),
          ),
        ),
        BlocProvider(
          create: (_) => ServiceRequestCubit(
            repository: ServiceRequestRepositoryImpl(client: supabaseClient),
            client: supabaseClient,
          ),
        ),
        BlocProvider(
          create: (_) => ServiceRequestsListCubit(
            repository: ServiceRequestRepositoryImpl(client: supabaseClient),
            client: supabaseClient,
          ),
        ),
        RepositoryProvider<ServiceRequestRepository>(
          create: (_) => ServiceRequestRepositoryImpl(client: supabaseClient),
        ),
        RepositoryProvider<ProductRepository>(
          create: (_) => ProductRepositoryImpl(client: supabaseClient),
        ),
        BlocProvider(
          create: (context) =>
              ProductsCubit(repository: context.read<ProductRepository>()),
        ),
        BlocProvider(
          create: (context) => ProductOrdersCubit(
            repository: context.read<ProductRepository>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: AppBrand.name,
        debugShowCheckedModeBanner: false,
        locale: AppLocale.locale,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: AppLocale.delegates,
        theme: AppTheme.light,
        routerConfig: AppRouter.createRouter(authCubit),
      ),
    );
  }
}
