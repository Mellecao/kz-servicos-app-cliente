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
        .select('*, service_categories(name, slug)')
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return response
        .map((json) => ServiceRequest.fromJson(json))
        .toList();
  }
}
