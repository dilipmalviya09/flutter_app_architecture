/// Exceptions are thrown in the Data layer and caught by Repository implementations.
/// They are then converted into Failures before returning to the Domain layer.

/// Thrown when the API/server returns a non-2xx response.
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

/// Thrown when no internet connection is available.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

/// Thrown when AWS Cognito or auth API rejects credentials.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

/// Thrown when SharedPreferences read/write fails.
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}