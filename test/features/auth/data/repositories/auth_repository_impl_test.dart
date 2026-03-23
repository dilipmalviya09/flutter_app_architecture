import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_architecture/core/error/exceptions.dart';
import 'package:flutter_app_architecture/core/error/failures.dart';
import 'package:flutter_app_architecture/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_app_architecture/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_app_architecture/features/auth/data/models/user_model.dart';
import 'package:flutter_app_architecture/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemote;
  late MockAuthLocalDataSource mockLocal;

  const testUserModel = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    accessToken: 'token-abc',
  );

  setUpAll(() {
    // Mocktail requires a fallback for any() matchers on custom types
    registerFallbackValue(testUserModel);
  });

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockLocal = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
    );
  });

  group('AuthRepositoryImpl.login', () {
    test('returns UserEntity and caches it on success', () async {
      when(() => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => testUserModel);

      when(() => mockLocal.cacheUser(any())).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'test@example.com',
        password: 'pass123',
      );

      expect(result, const Right(testUserModel));
      // Verify the user was cached after successful login
      verify(() => mockLocal.cacheUser(testUserModel)).called(1);
    });

    test('returns AuthFailure when AuthException is thrown', () async {
      // Use Future.error so the async exception propagates correctly
      when(() => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) => Future.error(const AuthException('Incorrect username or password.')),
      );

      final result = await repository.login(
        email: 'bad@example.com',
        password: 'wrong',
      );

      expect(result, const Left(AuthFailure('Incorrect username or password.')));
      // Verify user was NOT cached on failure
      verifyNever(() => mockLocal.cacheUser(any()));
    });

    test('returns ServerFailure when ServerException is thrown', () async {
      when(() => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) => Future.error(const ServerException('Server error. Please try again later.')),
      );

      final result = await repository.login(
        email: 'test@example.com',
        password: 'pass123',
      );

      expect(result, const Left(ServerFailure('Server error. Please try again later.')));
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('calls remote logout and clears local cache', () async {
      when(() => mockRemote.logout()).thenAnswer((_) async {});
      when(() => mockLocal.clearUser()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, const Right(null));
      verify(() => mockRemote.logout()).called(1);
      verify(() => mockLocal.clearUser()).called(1);
    });
  });
}