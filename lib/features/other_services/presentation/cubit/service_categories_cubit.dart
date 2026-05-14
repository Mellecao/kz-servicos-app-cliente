import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_category_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_state.dart';

class ServiceCategoriesCubit extends Cubit<ServiceCategoriesState> {
  ServiceCategoriesCubit({required ServiceCategoryRepository repository})
      : _repository = repository,
        super(const ServiceCategoriesInitial());

  final ServiceCategoryRepository _repository;

  Future<void> loadCategories() async {
    emit(const ServiceCategoriesLoading());
    try {
      final categories = await _repository.fetchCategories();
      emit(ServiceCategoriesLoaded(categories));
    } on Exception catch (e) {
      emit(ServiceCategoriesError(e.toString()));
    }
  }
}
