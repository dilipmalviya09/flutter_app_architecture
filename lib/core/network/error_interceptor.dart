import 'package:dio/dio.dart';
import '../error/exceptions.dart';

/// Converts Dio HTTP errors into typed [ServerException]s.
///
/// This ensures every feature's repository gets a consistent exception type
/// instead of having to handle raw DioExceptions everywhere.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    final message = switch (statusCode) {
      400 => 'Bad request. Please check your input.',
      401 => 'Session expired. Please log in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested resource was not found.',
      409 => 'Conflict. This resource already exists.',
      422 => 'Validation failed. Please check your data.',
      500 => 'Server error. Please try again later.',
      503 => 'Service unavailable. Please try again later.',
      _   => err.message ?? 'An unexpected error occurred.',
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: ServerException(message),
        type: err.type,
      ),
    );
  }
}