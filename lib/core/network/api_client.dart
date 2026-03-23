import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'logging_interceptor.dart';

/// Central Dio HTTP client used across all features.
///
/// Configured with:
/// - Base URL from AppConfig
/// - Timeouts
/// - Auth interceptor (attaches JWT token to every request)
/// - Error interceptor (normalizes API errors)
/// - Logging interceptor (debug only)
class ApiClient {
  late final Dio _dio;

  ApiClient({
    required String baseUrl,
    TokenProvider? tokenProvider,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      if (tokenProvider != null) AuthInterceptor(tokenProvider: tokenProvider),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

/// A function that returns the current JWT access token.
/// Injected into AuthInterceptor so it always uses the freshest token.
typedef TokenProvider = Future<String?> Function();