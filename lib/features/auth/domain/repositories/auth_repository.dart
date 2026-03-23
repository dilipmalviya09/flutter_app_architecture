import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Abstract contract for authentication operations.
///
/// The Domain layer defines WHAT to do.
/// The Data layer (AuthRepositoryImpl) decides HOW to do it.
///
/// This abstraction allows us to:
/// - Swap AWS Cognito for Firebase Auth without touching Domain or Presentation
/// - Easily mock in tests
abstract class AuthRepository {
  /// Logs in a user with email and password.
  /// Returns [UserEntity] on success, [Failure] on error.
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Logs out the current user and clears tokens.
  Future<Either<Failure, void>> logout();

  /// Returns the currently cached user, or null if not logged in.
  Future<Either<Failure, UserEntity?>> getCachedUser();
}