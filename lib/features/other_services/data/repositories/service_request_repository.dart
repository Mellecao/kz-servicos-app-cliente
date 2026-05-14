import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

abstract class ServiceRequestRepository {
  Future<void> createServiceRequest({
    required ServiceRequest request,
    required String clientId,
  });

  Future<List<ServiceRequest>> fetchServiceRequests({
    required String clientId,
  });
}
