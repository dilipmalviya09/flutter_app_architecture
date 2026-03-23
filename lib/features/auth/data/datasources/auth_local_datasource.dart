import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

const _cachedUserKey = 'CACHED_USER';

/// Handles local persistence of the authenticated user.
/// Stores the user as JSON in SharedPreferences.
///
/// In production, replace SharedPreferences with flutter_secure_storage
/// to encrypt tokens at rest.
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences prefs;

  const AuthLocalDataSourceImpl({required this.prefs});

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {
      throw const CacheException('Failed to cache user.');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = prefs.getString(_cachedUserKey);
      if (jsonString == null) return null;
      return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      throw const CacheException('Failed to read cached user.');
    }
  }

  @override
  Future<void> clearUser() async {
    await prefs.remove(_cachedUserKey);
  }
}