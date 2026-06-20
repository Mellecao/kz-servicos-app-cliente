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

    final categories = response
        .map((json) => ServiceCategory.fromJson(json))
        .toList();
    const priority = {
      'gestao-de-obra': 0,
      'gestao_de_obra': 0,
      'churrasqueiro': 1,
    };
    categories.sort((a, b) {
      final aPriority = priority[a.slug] ?? 100;
      final bPriority = priority[b.slug] ?? 100;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return a.name.compareTo(b.name);
    });
    return categories;
  }
}
