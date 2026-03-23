import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Business rule: Log in a user using email + password.
///
/// This UseCase:
/// 1. Validates input (basic null/empty checks)
/// 2. Delegates to AuthRepository
/// 3. Returns Either<Failure, UserEntity>
///
/// It does NOT know whether the data comes from AWS Cognito, Firebase, or a mock.
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    if (params.email.trim().isEmpty || params.password.isEmpty) {
      return const Left(AuthFailure('Email and password cannot be empty.'));
    }

    return repository.login(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

/// Input parameters for LoginUseCase.
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}