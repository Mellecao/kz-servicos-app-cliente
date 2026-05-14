import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';

class ServiceRequestRepositoryImpl implements ServiceRequestRepository {
  ServiceRequestRepositoryImpl({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> createServiceRequest({
    required ServiceRequest request,
    required String clientId,
  }) async {
    final json = request.toInsertJson(clientId: clientId);
    await _client.from('service_requests').insert(json);
  }

  @override
  Future<List<ServiceRequest>> fetchServiceRequests({
    required String clientId,
  }) async {
    final response = await _client
        .from('service_requests')
        .select('*, service_categories(name, slug)')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return response
        .map((json) => ServiceRequest.fromJson(json))
        .toList();
  }
}
