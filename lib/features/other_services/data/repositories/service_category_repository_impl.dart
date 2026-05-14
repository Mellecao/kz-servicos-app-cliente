import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_category_repository.dart';

class ServiceCategoryRepositoryImpl implements ServiceCategoryRepository {
  ServiceCategoryRepositoryImpl({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  @override
  Future<List<ServiceCategory>> fetchCategories({
    String serviceType = 'other_service',
  }) async {
    final response = await _client
        .from('service_categories')
        .select()
        .eq('service_type', serviceType)
        .eq('is_active', true)
        .order('name');

    return response
        .map((json) => ServiceCategory.fromJson(json))
        .toList();
  }
}
