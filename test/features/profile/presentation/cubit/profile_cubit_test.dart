import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:kz_servicos_app/features/profile/presentation/cubit/profile_state.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockPostgrestResponse extends Mock {
  final int count;
  MockPostgrestResponse({required this.count});
}

void main() {
  group('ProfileState', () {
    test('ProfileStats props are correct', () {
      const stats = ProfileStats(
        completedTrips: 5,
        requestedServices: 3,
        unreadMessages: 2,
      );
      expect(stats.props, [5, 3, 2]);
    });

    test('ProfileInitial has empty props', () {
      const state = ProfileInitial();
      expect(state.props, isEmpty);
    });

    test('ProfileLoading has empty props', () {
      const state = ProfileLoading();
      expect(state.props, isEmpty);
    });

    test('ProfileLoaded contains stats', () {
      const stats = ProfileStats(
        completedTrips: 10,
        requestedServices: 5,
        unreadMessages: 1,
      );
      const state = ProfileLoaded(stats);
      expect(state.stats, stats);
      expect(state.props, [stats]);
    });

    test('ProfileError contains message', () {
      const state = ProfileError('test error');
      expect(state.message, 'test error');
      expect(state.props, ['test error']);
    });

    test('ProfileStats equality works', () {
      const stats1 = ProfileStats(
        completedTrips: 5,
        requestedServices: 3,
        unreadMessages: 2,
      );
      const stats2 = ProfileStats(
        completedTrips: 5,
        requestedServices: 3,
        unreadMessages: 2,
      );
      expect(stats1, equals(stats2));
    });

    test('ProfileStats inequality works', () {
      const stats1 = ProfileStats(
        completedTrips: 5,
        requestedServices: 3,
        unreadMessages: 2,
      );
      const stats2 = ProfileStats(
        completedTrips: 10,
        requestedServices: 3,
        unreadMessages: 2,
      );
      expect(stats1, isNot(equals(stats2)));
    });
  });

  group('ProfileCubit', () {
    test('initial state is ProfileInitial', () {
      final mockClient = MockSupabaseClient();
      final cubit = ProfileCubit(client: mockClient);
      expect(cubit.state, const ProfileInitial());
      cubit.close();
    });
  });
}
