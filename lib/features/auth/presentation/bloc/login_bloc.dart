import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

/// LoginBloc manages all state transitions for the authentication flow.
///
/// Data flow:
///   UI dispatches Event → Bloc calls UseCase → UseCase calls Repository
///   → Repository returns Either<Failure, User> → Bloc emits new State → UI rebuilds
///
/// The Bloc does NOT know about:
/// - Dio, AWS, or any network library
/// - SharedPreferences or any storage library
/// - How login actually works — that is the UseCase's job
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;

  LoginBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
  }) : super(const LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    // fold: Left = failure, Right = success
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user)    => emit(LoginSuccess(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LoginLogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoggingOut());

    await logoutUseCase(const NoParams());

    emit(const LoginInitial());
  }
}