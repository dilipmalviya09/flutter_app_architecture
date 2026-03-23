import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_architecture/core/error/failures.dart';
import 'package:flutter_app_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_app_architecture/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app_architecture/features/auth/domain/usecases/login_usecase.dart';

// Create a mock for AuthRepository using mocktail
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  // Shared test data
  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    accessToken: 'token-abc',
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('returns UserEntity when repository succeeds', () async {
      // Arrange: repository will return a user
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Right(testUser));

      // Act
      final result = await useCase(
        const LoginParams(email: 'test@example.com', password: 'pass123'),
      );

      // Assert
      expect(result, const Right(testUser));
      verify(() => mockRepository.login(
            email: 'test@example.com',
            password: 'pass123',
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns AuthFailure when repository fails', () async {
      // Arrange
      when(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async =>
          const Left(AuthFailure('Incorrect username or password.')));

      // Act
      final result = await useCase(
        const LoginParams(email: 'bad@example.com', password: 'wrong'),
      );

      // Assert
      expect(result, const Left(AuthFailure('Incorrect username or password.')));
    });

    test('returns AuthFailure immediately when email is empty', () async {
      // The UseCase validates before calling the repository
      final result = await useCase(
        const LoginParams(email: '', password: 'pass123'),
      );

      expect(result, const Left(AuthFailure('Email and password cannot be empty.')));
      // Repository should NOT be called at all
      verifyNever(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    test('returns AuthFailure immediately when password is empty', () async {
      final result = await useCase(
        const LoginParams(email: 'test@example.com', password: ''),
      );

      expect(result, const Left(AuthFailure('Email and password cannot be empty.')));
      verifyNever(() => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });
  });
}