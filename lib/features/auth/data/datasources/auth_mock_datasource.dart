import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Mock datasource for local development and testing.
/// Simulates AWS Cognito without a real network call.
///
/// Valid test credentials:
///   Email    → test@example.com
///   Password → Test@1234
///
/// Use this in injection_container.dart during development:
///   sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthMockDataSource());
class AuthMockDataSource implements AuthRemoteDataSource {
  static const _validEmail    = 'test@example.com';
  static const _validPassword = 'Test@1234';

  String? _cachedToken;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email == _validEmail && password == _validPassword) {
      _cachedToken = 'mock-jwt-token-abc123';

      if (kDebugMode) debugPrint('[MockAuth] Login success for $email');

      return const UserModel(
        id: 'mock-user-001',
        email: _validEmail,
        accessToken: 'mock-jwt-token-abc123',
        name: 'Test User',
      );
    }

    // Simulate wrong credentials
    throw const AuthException('Incorrect username or password.');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cachedToken = null;
    if (kDebugMode) debugPrint('[MockAuth] Logged out');
  }

  @override
  Future<String?> getAccessToken() async => _cachedToken;
}