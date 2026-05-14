import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required SupabaseClient client})
      : _client = client,
        super(const ProfileInitial());

  final SupabaseClient _client;

  Future<void> loadStats(String userId) async {
    emit(const ProfileLoading());

    try {
      final results = await Future.wait([
        _countFinishedTrips(userId),
        _countServiceRequests(userId),
        _countUnreadMessages(userId),
      ]);

      emit(ProfileLoaded(ProfileStats(
        completedTrips: results[0],
        requestedServices: results[1],
        unreadMessages: results[2],
      )));
    } on Exception {
      emit(const ProfileError('Erro ao carregar dados do perfil'));
    }
  }

  Future<int> _countFinishedTrips(String userId) async {
    final response = await _client
        .from('trips')
        .select()
        .eq('client_id', userId)
        .eq('status', 'finished')
        .count(CountOption.exact);
    return response.count;
  }

  Future<int> _countServiceRequests(String userId) async {
    final response = await _client
        .from('service_requests')
        .select()
        .eq('client_id', userId)
        .count(CountOption.exact);
    return response.count;
  }

  Future<int> _countUnreadMessages(String userId) async {
    final response = await _client
        .from('chat_messages')
        .select('*, chat_rooms!inner()')
        .eq('chat_rooms.client_id', userId)
        .neq('sender_id', userId)
        .eq('is_read', false)
        .count(CountOption.exact);
    return response.count;
  }
}
