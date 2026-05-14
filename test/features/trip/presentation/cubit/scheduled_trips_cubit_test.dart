import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/scheduled_trips_state.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepo;
  late ScheduledTripsCubit cubit;

  final sampleTrips = [
    ScheduledTrip(
      id: 'trip-1',
      status: 'scheduled',
      scheduledDatetime: DateTime(2026, 4, 20, 10, 0),
      origin: 'Rua A, 100',
      destination: 'Rua B, 200',
      originLat: -23.55,
      originLng: -46.63,
      destinationLat: -23.57,
      destinationLng: -46.69,
      passengerCount: 2,
    ),
  ];

  setUp(() {
    mockRepo = MockTripRepository();
    cubit = ScheduledTripsCubit(repository: mockRepo);
  });

  tearDown(() => cubit.close());

  test('initial state is ScheduledTripsInitial', () {
    expect(cubit.state, isA<ScheduledTripsInitial>());
  });

  blocTest<ScheduledTripsCubit, ScheduledTripsState>(
    'load emits Loading then Loaded on success',
    build: () {
      when(() => mockRepo.getScheduledTrips('user-1'))
          .thenAnswer((_) async => sampleTrips);
      return cubit;
    },
    act: (c) => c.load('user-1'),
    expect: () => [
      isA<ScheduledTripsLoading>(),
      isA<ScheduledTripsLoaded>().having(
        (s) => s.trips.length,
        'trips count',
        1,
      ),
    ],
  );

  blocTest<ScheduledTripsCubit, ScheduledTripsState>(
    'load emits Loading then Error on failure',
    build: () {
      when(() => mockRepo.getScheduledTrips('user-1'))
          .thenThrow(Exception('DB error'));
      return cubit;
    },
    act: (c) => c.load('user-1'),
    expect: () => [
      isA<ScheduledTripsLoading>(),
      isA<ScheduledTripsError>(),
    ],
  );

  blocTest<ScheduledTripsCubit, ScheduledTripsState>(
    'refresh emits only Loaded without Loading',
    build: () {
      when(() => mockRepo.getScheduledTrips('user-1'))
          .thenAnswer((_) async => sampleTrips);
      return cubit;
    },
    act: (c) => c.refresh('user-1'),
    expect: () => [
      isA<ScheduledTripsLoaded>(),
    ],
  );
}
