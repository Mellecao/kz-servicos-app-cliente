import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

abstract class ServiceRequestRepository {
  /// Cria o service_request e retorna o `id` gerado (usado para upload de fotos).
  Future<String> createServiceRequest({
    required ServiceRequest request,
    required String clientId,
  });

  /// Faz upload das fotos ao Supabase Storage bucket `Service_Request_Photos`
  /// e cria linhas em `service_request_photos` com sort_order sequencial.
  Future<void> uploadPhotos({
    required String serviceRequestId,
    required List<String> localPaths,
  });

  Future<List<ServiceRequest>> fetchServiceRequests({
    required String clientId,
  });
}
