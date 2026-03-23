import 'package:equatable/equatable.dart';

/// Pure Dart class representing a logged-in user.
///
/// Rules:
/// - No Flutter imports
/// - No Dio/JSON imports
/// - No external library dependencies
/// - This is the single source of truth for what a "user" means in this app
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String accessToken;
  final String? name;

  const UserEntity({
    required this.id,
    required this.email,
    required this.accessToken,
    this.name,
  });

  @override
  List<Object?> get props => [id, email, accessToken, name];
}