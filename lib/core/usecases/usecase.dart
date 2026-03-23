import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base class for all UseCases.
///
/// [Type]   = the return type on success (e.g., UserEntity)
/// [Params] = the input parameters (e.g., LoginParams)
///
/// Every UseCase is callable like a function: useCase(params)
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this when a UseCase requires no parameters.
/// Example: LogoutUseCase(NoParams())
class NoParams {
  const NoParams();
}