import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/other_services/data/models/service_category.dart';
import 'package:kz_servicos_app/features/other_services/data/repositories/service_category_repository.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_cubit.dart';
import 'package:kz_servicos_app/features/other_services/presentation/cubit/service_categories_state.dart';

class MockServiceCategoryRepository extends Mock
    implements ServiceCategoryRepository {}

void main() {
  late MockServiceCategoryRepository mockRepository;
  late ServiceCategoriesCubit cubit;

  final testCategories = [
    ServiceCategory.fromJson({
      'id': 'uuid-1',
      'name': 'Eletricista',
      'slug': 'electrician',
      'service_type': 'other_service',
      'is_active': true,
    }),
    ServiceCategory.fromJson({
      'id': 'uuid-2',
      'name': 'Encanador',
      'slug': 'plumber',
      'service_type': 'other_service',
      'is_active': true,
    }),
  ];

  setUp(() {
    mockRepository = MockServiceCategoryRepository();
    cubit = ServiceCategoriesCubit(repository: mockRepository);
  });

  tearDown(() => cubit.close());

  group('ServiceCategoriesCubit', () {
    test('initial state is ServiceCategoriesInitial', () {
      expect(cubit.state, const ServiceCategoriesInitial());
    });

    blocTest<ServiceCategoriesCubit, ServiceCategoriesState>(
      'emits [Loading, Loaded] when loadCategories succeeds',
      build: () {
        when(() => mockRepository.fetchCategories(serviceType: any(named: 'serviceType')))
            .thenAnswer((_) async => testCategories);
        return cubit;
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        const ServiceCategoriesLoading(),
        isA<ServiceCategoriesLoaded>()
            .having((s) => s.categories.length, 'count', 2),
      ],
    );

    blocTest<ServiceCategoriesCubit, ServiceCategoriesState>(
      'emits [Loading, Error] when loadCategories fails',
      build: () {
        when(() => mockRepository.fetchCategories(serviceType: any(named: 'serviceType')))
            .thenThrow(Exception('Network error'));
        return cubit;
      },
      act: (cubit) => cubit.loadCategories(),
      expect: () => [
        const ServiceCategoriesLoading(),
        isA<ServiceCategoriesError>()
            .having((s) => s.message, 'message', contains('Network error')),
      ],
    );
  });
}
