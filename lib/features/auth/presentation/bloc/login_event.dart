part of 'login_bloc.dart';

/// All events that LoginBloc can receive.
/// Events are triggered by user actions in the UI.
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

/// User tapped the Login button with email and password.
class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// User tapped Logout.
class LoginLogoutRequested extends LoginEvent {
  const LoginLogoutRequested();
}