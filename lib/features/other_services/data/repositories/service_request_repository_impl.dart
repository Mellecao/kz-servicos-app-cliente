import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_request.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_request_repository.dart';

class ServiceRequestRepositoryImpl implements ServiceRequestRepository {
  ServiceRequestRepositoryImpl({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  static const _photosBucket = 'Service_Request_Photos';

  @override
  Future<String> createServiceRequest({
    required ServiceRequest request,
    required String clientId,
  }) async {
    final json = request.toInsertJson(clientId: clientId);
    final response = await _client
        .from('service_requests')
        .insert(json)
        .select('id')
        .single();
    return response['id'] as String;
  }

  @override
  Future<void> uploadPhotos({
    required String serviceRequestId,
    required List<String> localPaths,
  }) async {
    for (var i = 0; i < localPaths.length; i++) {
      final path = localPaths[i];
      final file = File(path);
      if (!file.existsSync()) continue;
      final ext = path.split('.').last.toLowerCase();
      final storagePath = '$serviceRequestId/$i.$ext';
      await _client.storage.from(_photosBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl =
          _client.storage.from(_photosBucket).getPublicUrl(storagePath);
      await _client.from('service_request_photos').insert({
        'service_request_id': serviceRequestId,
        'photo_url': publicUrl,
        'sort_order': i,
      });
    }
  }

  @override
  Future<List<ServiceRequest>> fetchServiceRequests({
    required String clientId,
  }) async {
    final response = await _client
        .from('service_requests')
        .select(ServiceRequest.selectColumns)
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return response
        .map((json) => ServiceRequest.fromJson(json))
        .toList();
  }
  @override
  Future<ServiceRequest> fetchServiceRequestById(String id) async {
    final row = await _client
        .from('service_requests')
        .select(ServiceRequest.selectColumns)
        .eq('id', id)
        .single();
    return ServiceRequest.fromJson(row);
  }

  /// UPDATE com `.select()`: se o RLS ou o estado atual não deixarem alterar
  /// nada, o Postgres devolve 0 linhas sem erro; aqui isso passa a erro visível.
  Future<void> _updateStatus(
    String id, {
    required String to,
    required List<String> from,
    required String failMessage,
  }) async {
    final rows = await _client
        .from('service_requests')
        .update({'status': to})
        .eq('id', id)
        .inFilter('status', from)
        .select('id');
    if (rows.isEmpty) throw ServiceRequestActionException(failMessage);
  }

  @override
  Future<void> acceptProvider(String id) => _updateStatus(
    id,
    to: 'assigned',
    from: const ['awaiting_client_confirmation'],
    failMessage:
        'Não foi possível aceitar: o pedido mudou de estado. Atualizámos o ecrã.',
  );

  @override
  Future<void> cancelServiceRequest(String id) => _updateStatus(
    id,
    to: 'cancelled',
    from: [
      for (final s in ServiceRequestStatus.values)
        if (s.canCancel) s.dbValue,
    ],
    failMessage:
        'Não foi possível cancelar: o serviço já começou ou o pedido mudou.',
  );

  @override
  Future<String> ensureChatRoom({
    required String serviceRequestId,
    required String providerUserId,
  }) async {
    final existing = await _client
        .from('chat_rooms')
        .select('id')
        .eq('service_request_id', serviceRequestId)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;
    final clientId = _client.auth.currentUser?.id;
    if (clientId == null) {
      throw const ServiceRequestActionException(
        'Sessão expirada. Inicie sessão novamente.',
      );
    }
    final inserted = await _client
        .from('chat_rooms')
        .insert({
          'service_request_id': serviceRequestId,
          'client_id': clientId,
          'provider_id': providerUserId,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  @override
  Stream<void> requestChanges(String id) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('service-request-$id')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'service_requests',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: id,
              ),
              callback: (_) {
                if (!controller.isClosed) controller.add(null);
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _client.removeChannel(c);
        await controller.close();
      },
    );
    return controller.stream;
  }
}
