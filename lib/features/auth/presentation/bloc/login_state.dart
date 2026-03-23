part of 'login_bloc.dart';

/// All possible UI states for the login screen.
/// The UI rebuilds every time the state changes.
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state — form is empty and ready.
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Login is in progress — show a loading spinner.
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Login succeeded — navigate to the home screen.
class LoginSuccess extends LoginState {
  final UserEntity user;

  const LoginSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

/// Login failed — show an error message.
class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// User is being logged out.
class LoginLoggingOut extends LoginState {
  const LoginLoggingOut();
}