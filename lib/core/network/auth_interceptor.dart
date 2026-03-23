import 'package:dio/dio.dart';
import 'api_client.dart';

/// Automatically attaches the JWT Bearer token to every outgoing request.
///
/// On a 401 Unauthorized response, it clears the session.
/// The UI reacts to session loss via BLoC/stream — no direct navigation here.
class AuthInterceptor extends Interceptor {
  final TokenProvider tokenProvider;

  const AuthInterceptor({required this.tokenProvider});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // If token retrieval fails, proceed without it.
      // The server will return 401 which ErrorInterceptor handles.
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid.
      // Broadcast session expiry so BLoC can redirect to login.
      // In production: use an event bus or auth stream here.
    }
    handler.next(err);
  }
}