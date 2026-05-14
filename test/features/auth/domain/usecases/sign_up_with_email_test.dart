import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/auth/domain/entities/app_user.dart';
import 'package:kz_servicos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:kz_servicos_app/features/auth/domain/usecases/sign_up_with_email.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpWithEmail useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpWithEmail(mockRepository);
  });

  const testUser = AppUser(
    id: '123',
    fullName: 'Maria Silva',
    email: 'maria@email.com',
    role: 'client',
    phone: '(11) 99999-9999',
  );

  group('SignUpWithEmail', () {
    test('returns AppUser when signup succeeds with session', () async {
      when(() => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
          )).thenAnswer((_) async => testUser);

      final result = await useCase(
        email: 'maria@email.com',
        password: '123456',
        fullName: 'Maria Silva',
        phone: '(11) 99999-9999',
      );

      expect(result, equals(testUser));
      verify(() => mockRepository.signUpWithEmail(
            email: 'maria@email.com',
            password: '123456',
            fullName: 'Maria Silva',
            phone: '(11) 99999-9999',
          )).called(1);
    });

    test('returns null when email confirmation is required', () async {
      when(() => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
          )).thenAnswer((_) async => null);

      final result = await useCase(
        email: 'maria@email.com',
        password: '123456',
        fullName: 'Maria Silva',
        phone: '(11) 99999-9999',
      );

      expect(result, isNull);
    });

    test('rethrows exception from repository', () async {
      when(() => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
          )).thenThrow(Exception('Network error'));

      expect(
        () => useCase(
          email: 'maria@email.com',
          password: '123456',
          fullName: 'Maria Silva',
          phone: '(11) 99999-9999',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
