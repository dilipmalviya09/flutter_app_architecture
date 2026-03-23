import 'package:equatable/equatable.dart';

/// Base class for all failures in the app.
/// A Failure represents a known, handled error (e.g., network error, auth error).
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Returned when the server/API returns an error response.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Returned when there is no internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Returned when authentication fails (wrong credentials, expired token).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Returned when local cache read/write fails.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}