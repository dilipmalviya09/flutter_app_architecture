import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_mock_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';

/// Global service locator instance.
/// Access anywhere via: sl<SomeType>()
final sl = GetIt.instance;

/// Registers all dependencies.
/// Called once in main() before runApp().
///
/// Registration types:
/// - [registerLazySingleton]  → created once, reused everywhere (services, repos)
/// - [registerFactory]        → new instance each time (BLoCs — one per screen)
/// - [registerSingleton]      → created immediately at startup (rare)
Future<void> initDependencies() async {
  // ── External ────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ── Network ─────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(prefs: sl()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: 'https://your-api.example.com', // Replace with real base URL
      tokenProvider: () async {
        // Read token from the local datasource
        final user = await sl<AuthLocalDataSource>().getCachedUser();
        return user?.accessToken;
      },
    ),
  );

  sl.registerLazySingleton<Dio>(() => sl<ApiClient>().dio);

  // ── Auth Feature ─────────────────────────────────────────────────

  // Data Sources
  // kDebugMode  → uses AuthMockDataSource (no AWS needed, test credentials below)
  // !kDebugMode → uses real AWS Cognito via AuthRemoteDataSourceImpl
  //
  // Test credentials (mock only):
  //   Email    : test@example.com
  //   Password : Test@1234
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => kDebugMode
        ? AuthMockDataSource()
        : AuthRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // BLoC — registerFactory = new instance per screen, not shared
  sl.registerFactory(
    () => LoginBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );
}