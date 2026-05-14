import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_requests_list_state.dart';

class ServiceRequestsListCubit extends Cubit<ServiceRequestsListState> {
  ServiceRequestsListCubit({
    required ServiceRequestRepository repository,
    required SupabaseClient client,
  })  : _repository = repository,
        _client = client,
        super(const ServiceRequestsListInitial());

  final ServiceRequestRepository _repository;
  final SupabaseClient _client;

  Future<void> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      emit(const ServiceRequestsListError('Usuário não autenticado'));
      return;
    }
    emit(const ServiceRequestsListLoading());
    try {
      final requests = await _repository.fetchServiceRequests(
        clientId: userId,
      );
      emit(ServiceRequestsListLoaded(requests));
    } on Exception catch (e) {
      emit(ServiceRequestsListError(e.toString()));
    }
  }
}
