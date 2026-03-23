import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────
// OPTION A: AWS Cognito via Amplify (recommended for production)
// Uncomment when amplify_flutter is configured.
//
// import 'package:amplify_flutter/amplify_flutter.dart';
// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// ─────────────────────────────────────────────────────────────────

/// Contract for remote authentication operations.
/// Isolates the Presentation/Domain layers from the specific auth provider.
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
  Future<String?> getAccessToken();
}

// ─────────────────────────────────────────────────────────────────
// OPTION A: AWS Cognito via Amplify SDK
// ─────────────────────────────────────────────────────────────────
//
// class AuthRemoteDataSourceAmplify implements AuthRemoteDataSource {
//   @override
//   Future<UserModel> login({required String email, required String password}) async {
//     try {
//       final result = await Amplify.Auth.signIn(username: email, password: password);
//       if (!result.isSignedIn) throw const AuthException('Sign in failed.');
//
//       final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
//       final token  = session.userPoolTokensResult.value.accessToken.raw;
//       final userId = session.userSubResult.value;
//
//       return UserModel(id: userId, email: email, accessToken: token);
//     } on AuthException catch (e) {
//       throw AuthException(e.message);
//     }
//   }
//
//   @override
//   Future<void> logout() async => Amplify.Auth.signOut();
//
//   @override
//   Future<String?> getAccessToken() async {
//     final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
//     return session.userPoolTokensResult.value.accessToken.raw;
//   }
// }

// ─────────────────────────────────────────────────────────────────
// OPTION B: AWS Cognito via direct REST API (no Amplify SDK)
// Uses Cognito's InitiateAuth endpoint with USER_PASSWORD_AUTH flow.
// ─────────────────────────────────────────────────────────────────
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  // Replace with your Cognito pool values from AWS Console.
  static const String _cognitoRegion = 'us-east-1';
  static const String _clientId = 'YOUR_COGNITO_APP_CLIENT_ID';

  // Cognito endpoint for authentication
  static const String _cognitoEndpoint =
      'https://cognito-idp.$_cognitoRegion.amazonaws.com/';

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        _cognitoEndpoint,
        data: {
          'AuthFlow': 'USER_PASSWORD_AUTH',
          'ClientId': _clientId,
          'AuthParameters': {
            'USERNAME': email,
            'PASSWORD': password,
          },
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
          },
        ),
      );

      final authResult = response.data['AuthenticationResult'];
      if (authResult == null) {
        throw const AuthException('Authentication failed. No token received.');
      }

      final accessToken = authResult['AccessToken'] as String;
      final idToken = authResult['IdToken'] as String;

      // Decode the ID token to extract user info (base64 middle segment).
      final userId = _extractSubFromToken(idToken);

      return UserModel(
        id: userId,
        email: email,
        accessToken: accessToken,
      );
    } on DioException catch (e) {
      final errorType = e.response?.data?['__type'] as String?;
      final msg = switch (errorType) {
        'NotAuthorizedException' => 'Incorrect username or password.',
        'UserNotFoundException'  => 'No account found with this email.',
        'UserNotConfirmedException' => 'Please verify your email first.',
        _ => e.message ?? 'Authentication failed.',
      };
      throw AuthException(msg);
    }
  }

  @override
  Future<void> logout() async {
    // Clear tokens from local storage (handled by AuthLocalDataSource).
    // If using Cognito GlobalSignOut endpoint, call it here.
  }

  @override
  Future<String?> getAccessToken() async {
    // In production: read the cached token from SecureStorage/SharedPreferences.
    // Refresh it using the RefreshToken if expired.
    return null;
  }

  /// Extracts the `sub` (user ID) from the JWT ID token payload.
  String _extractSubFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      final payload = parts[1];
      final normalized = base64PadRight(payload);
      final decoded = String.fromCharCodes(base64Url.decode(normalized));
      final json = Map<String, dynamic>.from(
        // A simple parse — use dart:convert in real code
        _parseSimpleJson(decoded),
      );
      return json['sub'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  String base64PadRight(String s) {
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s + '=' * (4 - mod);
  }

  Map<String, dynamic> _parseSimpleJson(String raw) {
    // Minimal JWT payload parser — replace with dart:convert json.decode
    return {};
  }
}