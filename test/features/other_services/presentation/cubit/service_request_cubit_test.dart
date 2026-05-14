import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_state.dart';

class MockServiceRequestRepository extends Mock
    implements ServiceRequestRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

void main() {
  late MockServiceRequestRepository mockRepository;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late ServiceRequestCubit cubit;

  final testRequest = ServiceRequest(
    id: 'test-id',
    categoryId: 'uuid-category',
    categoryName: 'Eletricista',
    problem: 'Curto-circuito',
    details: 'Detalhe do problema',
    mediaPaths: [],
    urgency: UrgencyType.now,
    status: ServiceRequestStatus.searchingProvider,
    createdAt: DateTime(2026, 4, 19),
  );

  setUpAll(() {
    registerFallbackValue(testRequest);
  });

  setUp(() {
    mockRepository = MockServiceRequestRepository();
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);

    cubit = ServiceRequestCubit(
      repository: mockRepository,
      client: mockClient,
    );
  });

  tearDown(() => cubit.close());

  group('ServiceRequestCubit', () {
    test('initial state is ServiceRequestInitial', () {
      expect(cubit.state, const ServiceRequestInitial());
    });

    blocTest<ServiceRequestCubit, ServiceRequestState>(
      'emits [Submitting, Success] when submit succeeds',
      build: () {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-uuid-123');
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockRepository.createServiceRequest(
              request: any(named: 'request'),
              clientId: any(named: 'clientId'),
            )).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.submit(testRequest),
      expect: () => [
        const ServiceRequestSubmitting(),
        const ServiceRequestSuccess(),
      ],
    );

    blocTest<ServiceRequestCubit, ServiceRequestState>(
      'emits [Submitting, Error] when user is not authenticated',
      build: () {
        when(() => mockAuth.currentUser).thenReturn(null);
        return cubit;
      },
      act: (cubit) => cubit.submit(testRequest),
      expect: () => [
        const ServiceRequestSubmitting(),
        const ServiceRequestError('Usuário não autenticado'),
      ],
    );

    blocTest<ServiceRequestCubit, ServiceRequestState>(
      'emits [Submitting, Error] when repository throws',
      build: () {
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user-uuid-123');
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockRepository.createServiceRequest(
              request: any(named: 'request'),
              clientId: any(named: 'clientId'),
            )).thenThrow(Exception('Server error'));
        return cubit;
      },
      act: (cubit) => cubit.submit(testRequest),
      expect: () => [
        const ServiceRequestSubmitting(),
        isA<ServiceRequestError>()
            .having((s) => s.message, 'message', contains('Server error')),
      ],
    );

    blocTest<ServiceRequestCubit, ServiceRequestState>(
      'reset emits initial state',
      build: () => cubit,
      seed: () => const ServiceRequestSuccess(),
      act: (cubit) => cubit.reset(),
      expect: () => [const ServiceRequestInitial()],
    );
  });
}
