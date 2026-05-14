import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';

abstract class ServiceCategoryRepository {
  Future<List<ServiceCategory>> fetchCategories({
    String serviceType = 'other_service',
  });
}
