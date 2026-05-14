import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';

abstract class ServiceCategoriesState extends Equatable {
  const ServiceCategoriesState();

  @override
  List<Object?> get props => [];
}

class ServiceCategoriesInitial extends ServiceCategoriesState {
  const ServiceCategoriesInitial();
}

class ServiceCategoriesLoading extends ServiceCategoriesState {
  const ServiceCategoriesLoading();
}

class ServiceCategoriesLoaded extends ServiceCategoriesState {
  const ServiceCategoriesLoaded(this.categories);

  final List<ServiceCategory> categories;

  @override
  List<Object?> get props => [categories];
}

class ServiceCategoriesError extends ServiceCategoriesState {
  const ServiceCategoriesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
