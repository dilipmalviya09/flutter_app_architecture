import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_architecture/core/error/failures.dart';
import 'package:flutter_app_architecture/core/usecases/usecase.dart';
import 'package:flutter_app_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_app_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_app_architecture/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_app_architecture/features/auth/presentation/bloc/login_bloc.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  late LoginBloc loginBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    accessToken: 'token-abc',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    loginBloc = LoginBloc(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
    );

    // Required by mocktail to handle any() matchers with custom types
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const NoParams());
  });

  tearDown(() => loginBloc.close());

  group('LoginBloc', () {
    test('initial state is LoginInitial', () {
      expect(loginBloc.state, const LoginInitial());
    });

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginSuccess] when login succeeds',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => const Right(testUser));
        return loginBloc;
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'test@example.com', password: 'pass123'),
      ),
      expect: () => [
        const LoginLoading(),
        const LoginSuccess(testUser),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginFailure] when login fails',
      build: () {
        when(() => mockLoginUseCase(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Incorrect username or password.')),
        );
        return loginBloc;
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'bad@example.com', password: 'wrong'),
      ),
      expect: () => [
        const LoginLoading(),
        const LoginFailure('Incorrect username or password.'),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoggingOut, LoginInitial] when logout is requested',
      build: () {
        when(() => mockLogoutUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return loginBloc;
      },
      act: (bloc) => bloc.add(const LoginLogoutRequested()),
      expect: () => [
        const LoginLoggingOut(),
        const LoginInitial(),
      ],
    );
  });
}