import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_request_state.dart';

class ServiceRequestCubit extends Cubit<ServiceRequestState> {
  ServiceRequestCubit({
    required ServiceRequestRepository repository,
    required SupabaseClient client,
  })  : _repository = repository,
        _client = client,
        super(const ServiceRequestInitial());

  final ServiceRequestRepository _repository;
  final SupabaseClient _client;

  Future<void> submit(ServiceRequest request) async {
    emit(const ServiceRequestSubmitting());
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        emit(const ServiceRequestError('Usuário não autenticado'));
        return;
      }
      await _repository.createServiceRequest(
        request: request,
        clientId: userId,
      );
      emit(const ServiceRequestSuccess());
    } on Exception catch (e) {
      emit(ServiceRequestError(e.toString()));
    }
  }

  void reset() => emit(const ServiceRequestInitial());
}
