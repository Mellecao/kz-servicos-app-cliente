import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/flash_trip_repository.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/flash_searching_cubit.dart';
import 'package:kz_servicos_app/features/trip/presentation/cubit/flash_searching_state.dart';

class _MockRepo extends Mock implements FlashTripRepository {}

void main() {
  late _MockRepo repo;
  const tripId = 'trip-1';

  setUp(() {
    repo = _MockRepo();
    when(() => repo.watchProposals(tripId))
        .thenAnswer((_) => Stream.value([
              {
                'id': 'cand-1',
                'trip_id': tripId,
                'driver_profile_id': 'd1',
                'offered_price': '55.00',
                'created_at': '2026-07-29T12:00:00Z',
                'status': 'accepted',
                'driver_profiles': {
                  'photo_url': null,
                  'provider_profiles': {
                    'user': {'name': 'João'}
                  },
                  'vehicles': [
                    {'brand': 'Onix', 'model': 'LT', 'color': 'Prata'}
                  ],
                },
              }
            ]));
    when(() => repo.watchTripStatus(tripId))
        .thenAnswer((_) => Stream.value({'status': 'searching_drivers'}));
  });

  blocTest<FlashSearchingCubit, FlashSearchingState>(
    'emits FlashSearchingProposals when a proposal arrives',
    build: () => FlashSearchingCubit(repository: repo, tripId: tripId),
    act: (c) => c.start(),
    wait: const Duration(milliseconds: 100),
    expect: () => [isA<FlashSearchingProposals>()],
  );

  blocTest<FlashSearchingCubit, FlashSearchingState>(
    'emits FlashSearchingReadyToStart on status=started',
    build: () {
      when(() => repo.watchTripStatus(tripId))
          .thenAnswer((_) => Stream.value({'status': 'started'}));
      when(() => repo.watchProposals(tripId))
          .thenAnswer((_) => const Stream.empty());
      return FlashSearchingCubit(repository: repo, tripId: tripId);
    },
    act: (c) => c.start(),
    wait: const Duration(milliseconds: 100),
    expect: () => [isA<FlashSearchingReadyToStart>()],
  );

  blocTest<FlashSearchingCubit, FlashSearchingState>(
    'emits FlashSearchingCancelled on status=cancelled',
    build: () {
      when(() => repo.watchTripStatus(tripId))
          .thenAnswer((_) => Stream.value({'status': 'cancelled'}));
      when(() => repo.watchProposals(tripId))
          .thenAnswer((_) => const Stream.empty());
      return FlashSearchingCubit(repository: repo, tripId: tripId);
    },
    act: (c) => c.start(),
    wait: const Duration(milliseconds: 100),
    expect: () => [isA<FlashSearchingCancelled>()],
  );
}
