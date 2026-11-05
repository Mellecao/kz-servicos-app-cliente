import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';

/// Falha de uma ação sobre um pedido que o utilizador deve ver (por exemplo, o
/// estado já mudou). A [message] vem em pt-AO.
class ServiceRequestActionException implements Exception {
  const ServiceRequestActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

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

  /// Pedido com categoria, prestador e preço final.
  Future<ServiceRequest> fetchServiceRequestById(String id);

  /// O cliente aceita o prestador escolhido: `awaiting_client_confirmation →
  /// assigned` (o trigger do banco passa-o a `awaiting_provider_confirmation`).
  /// Lança [ServiceRequestActionException] se nenhuma linha for atualizada.
  Future<void> acceptProvider(String id);

  /// Cancela o pedido enquanto ainda não começou. Lança
  /// [ServiceRequestActionException] se nenhuma linha for atualizada.
  Future<void> cancelServiceRequest(String id);

  /// Devolve o id da sala de chat do pedido (cria-a se ainda não existir).
  Future<String> ensureChatRoom({
    required String serviceRequestId,
    required String providerUserId,
  });

  /// Emite um evento sempre que o pedido muda (realtime em `service_requests`).
  Stream<void> requestChanges(String id);
}
