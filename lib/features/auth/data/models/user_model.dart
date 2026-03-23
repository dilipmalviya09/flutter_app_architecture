import '../../domain/entities/user_entity.dart';

/// Data-layer representation of a user.
///
/// Extends [UserEntity] and adds JSON serialization.
/// This is the only class that knows about JSON — the domain entity stays pure.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.accessToken,
    super.name,
  });

  /// Creates a UserModel from a JSON map (e.g., API response body).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['sub'] as String? ?? json['id'] as String,
      email: json['email'] as String,
      accessToken: json['access_token'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  /// Converts this model to a JSON map (e.g., for local caching).
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'access_token': accessToken,
        'name': name,
      };

  /// Creates a UserModel from a cached JSON string.
  factory UserModel.fromJsonString(Map<String, dynamic> json) =>
      UserModel.fromJson(json);
}