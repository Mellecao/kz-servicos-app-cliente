import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:kz_servicos_app/features/trip/domain/usecases/create_trip.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/trip_creation_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/trip_creation_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;
  late CreateTrip createTrip;
  late TripCreationCubit cubit;

  const pickupAddress = TripAddress(
    formattedAddress: 'Rua A, 100 - São Paulo - SP',
    city: 'São Paulo',
    state: 'SP',
    latitude: -23.55,
    longitude: -46.63,
  );

  const dropoffAddress = TripAddress(
    formattedAddress: 'Av. B, 200 - São Paulo - SP',
    city: 'São Paulo',
    state: 'SP',
    latitude: -23.57,
    longitude: -46.65,
  );

  final tripRequest = TripRequest(
    clientId: 'user-uuid-123',
    pickupAddress: pickupAddress,
    dropoffAddress: dropoffAddress,
    scheduledDatetime: DateTime(2026, 4, 20, 14, 30),
    passengerCount: 2,
    observations: 'Test',
  );

  final createdTrip = Trip(
    id: 'trip-uuid-999',
    clientId: 'user-uuid-123',
    status: 'open',
    scheduledDatetime: DateTime(2026, 4, 20, 14, 30),
    passengerCount: 2,
    observations: 'Test',
    createdAt: DateTime(2026, 4, 18),
  );

  setUpAll(() {
    registerFallbackValue(tripRequest);
  });

  setUp(() {
    mockRepository = MockTripRepository();
    createTrip = CreateTrip(mockRepository);
    cubit = TripCreationCubit(createTrip: createTrip);
  });

  tearDown(() => cubit.close());

  group('CreateTrip use case', () {
    test('delegates to repository', () async {
      when(() => mockRepository.createTrip(any()))
          .thenAnswer((_) async => createdTrip);

      final result = await createTrip(tripRequest);

      expect(result.id, 'trip-uuid-999');
      verify(() => mockRepository.createTrip(tripRequest)).called(1);
    });
  });

  group('TripCreationCubit', () {
    test('initial state is TripCreationInitial', () {
      expect(cubit.state, const TripCreationInitial());
    });

    blocTest<TripCreationCubit, TripCreationState>(
      'emits [Loading, Success] on successful trip creation',
      build: () {
        when(() => mockRepository.createTrip(any()))
            .thenAnswer((_) async => createdTrip);
        return cubit;
      },
      act: (cubit) => cubit.submit(tripRequest),
      expect: () => [
        const TripCreationLoading(),
        const TripCreationSuccess(tripId: 'trip-uuid-999'),
      ],
    );

    blocTest<TripCreationCubit, TripCreationState>(
      'emits [Loading, Error] when repository throws',
      build: () {
        when(() => mockRepository.createTrip(any()))
            .thenThrow(Exception('DB error'));
        return cubit;
      },
      act: (cubit) => cubit.submit(tripRequest),
      expect: () => [
        const TripCreationLoading(),
        const TripCreationError(
          message: 'Não foi possível criar a viagem. Tente novamente.',
        ),
      ],
    );

    blocTest<TripCreationCubit, TripCreationState>(
      'reset emits TripCreationInitial',
      build: () => cubit,
      seed: () => const TripCreationSuccess(tripId: 'trip-1'),
      act: (cubit) => cubit.reset(),
      expect: () => [const TripCreationInitial()],
    );
  });
}
