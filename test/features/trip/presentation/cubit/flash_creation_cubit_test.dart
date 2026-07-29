import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/flash_trip_repository.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/flash_creation_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/flash_creation_state.dart';

class _MockRepo extends Mock implements FlashTripRepository {}

void main() {
  late _MockRepo repo;
  setUp(() {
    repo = _MockRepo();
  });

  blocTest<FlashCreationCubit, FlashCreationState>(
    'emits [Loading, Success] on happy path',
    build: () {
      when(() => repo.createFlashTrip(
            pickupAddressId: any(named: 'pickupAddressId'),
            dropoffAddressId: any(named: 'dropoffAddressId'),
            serviceCategoryId: any(named: 'serviceCategoryId'),
            passengerCount: any(named: 'passengerCount'),
            childrenCount: any(named: 'childrenCount'),
            luggageCount: any(named: 'luggageCount'),
            observations: any(named: 'observations'),
          )).thenAnswer((_) async => 'trip-xyz');
      return FlashCreationCubit(repository: repo);
    },
    act: (c) => c.submit(
      pickupAddressId: 'p',
      dropoffAddressId: 'd',
      serviceCategoryId: 'cat',
      passengerCount: 1,
      childrenCount: 0,
      luggageCount: 0,
      observations: '',
    ),
    expect: () => [
      isA<FlashCreationLoading>(),
      isA<FlashCreationSuccess>()
          .having((s) => s.tripId, 'tripId', 'trip-xyz'),
    ],
  );

  blocTest<FlashCreationCubit, FlashCreationState>(
    'emits [Loading, Error] on repo failure',
    build: () {
      when(() => repo.createFlashTrip(
            pickupAddressId: any(named: 'pickupAddressId'),
            dropoffAddressId: any(named: 'dropoffAddressId'),
            serviceCategoryId: any(named: 'serviceCategoryId'),
            passengerCount: any(named: 'passengerCount'),
            childrenCount: any(named: 'childrenCount'),
            luggageCount: any(named: 'luggageCount'),
            observations: any(named: 'observations'),
          )).thenThrow(Exception('boom'));
      return FlashCreationCubit(repository: repo);
    },
    act: (c) => c.submit(
      pickupAddressId: 'p',
      dropoffAddressId: 'd',
      serviceCategoryId: 'cat',
      passengerCount: 1,
      childrenCount: 0,
      luggageCount: 0,
      observations: '',
    ),
    expect: () => [
      isA<FlashCreationLoading>(),
      isA<FlashCreationError>(),
    ],
  );
}
