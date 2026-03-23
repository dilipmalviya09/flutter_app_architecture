# Flutter Feature-Based Clean Architecture

A production-ready Flutter starter implementing **Feature-Based Clean Architecture** with BLoC state management, AWS Cognito authentication, and a full testing suite.

Built for large-scale enterprise apps that need to be **scalable**, **maintainable**, and **testable**.

---

## Table of Contents

1. [What Problem Does This Solve?](#what-problem-does-this-solve)
2. [Architecture Overview](#architecture-overview)
3. [Folder Structure](#folder-structure)
4. [The Three Layers Explained](#the-three-layers-explained)
5. [Data Flow — Step by Step](#data-flow--step-by-step)
6. [State Management with BLoC](#state-management-with-bloc)
7. [Dependency Injection](#dependency-injection)
8. [Network Layer](#network-layer)
9. [AWS Cognito Integration](#aws-cognito-integration)
10. [Error Handling](#error-handling)
11. [Testing](#testing)
12. [How to Add a New Feature](#how-to-add-a-new-feature)
13. [Running the App](#running-the-app)
14. [Dependencies](#dependencies)

---

## What Problem Does This Solve?

Most Flutter apps start simple but grow messy. When one file handles API calls, business logic, and UI together, small changes break unrelated things and testing becomes nearly impossible.

This architecture separates every concern into its own place so that:

- A UI developer never touches API code
- Business rules never depend on Flutter widgets
- Every piece can be tested in isolation
- New features can be added without touching existing ones

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                 │
│         Pages · Widgets · BLoC (Events/States)      │
│   What the user sees. Reacts to state changes.      │
├─────────────────────────────────────────────────────┤
│                    DOMAIN LAYER                     │
│         Entities · UseCases · Repository Contracts  │
│   Pure Dart. Zero Flutter/Dio dependencies.         │
│   The brain — defines WHAT the app does.            │
├─────────────────────────────────────────────────────┤
│                     DATA LAYER                      │
│   DataSources · Models · Repository Implementations │
│   Knows about APIs, databases, SharedPreferences.   │
│   The hands — knows HOW to get/store data.          │
└─────────────────────────────────────────────────────┘
```

**Key rule:** Each layer only communicates with the layer directly below it. The Domain layer never imports from Data. The Presentation layer never calls an API directly.

---

## Folder Structure

```
flutter_app_architecture/
├── lib/
│   ├── main.dart                          # Entry point, DI initialization
│   │
│   ├── core/                              # Shared across ALL features
│   │   ├── di/
│   │   │   └── injection_container.dart   # GetIt dependency registration
│   │   ├── error/
│   │   │   ├── failures.dart              # Failure types (ServerFailure, AuthFailure…)
│   │   │   └── exceptions.dart            # Exception types (ServerException, AuthException…)
│   │   ├── network/
│   │   │   ├── api_client.dart            # Dio HTTP client factory
│   │   │   ├── auth_interceptor.dart      # Attaches JWT token to every request
│   │   │   ├── error_interceptor.dart     # Converts HTTP errors to typed exceptions
│   │   │   └── logging_interceptor.dart   # Debug-only request/response logging
│   │   └── usecases/
│   │       └── usecase.dart               # Base UseCase<Type, Params> abstract class
│   │
│   └── features/
│       ├── auth/                          # Authentication feature (self-contained)
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── auth_remote_datasource.dart  # AWS Cognito API calls
│       │   │   │   └── auth_local_datasource.dart   # SharedPreferences (token cache)
│       │   │   ├── models/
│       │   │   │   └── user_model.dart    # UserEntity + JSON serialization
│       │   │   └── repositories/
│       │   │       └── auth_repository_impl.dart    # Implements AuthRepository
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── user_entity.dart   # Pure Dart user object
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository.dart  # Abstract contract
│       │   │   └── usecases/
│       │   │       ├── login_usecase.dart
│       │   │       └── logout_usecase.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── login_bloc.dart    # Orchestrates login flow
│       │       │   ├── login_event.dart   # LoginSubmitted, LoginLogoutRequested
│       │       │   └── login_state.dart   # LoginInitial, Loading, Success, Failure
│       │       ├── pages/
│       │       │   └── login_page.dart    # Full login screen
│       │       └── widgets/
│       │           └── login_form.dart    # Reusable form widget
│       │
│       └── home/                          # Home feature (add more features here)
│           └── presentation/
│               └── pages/
│                   └── home_page.dart
│
├── test/
│   ├── features/
│   │   └── auth/
│   │       ├── data/repositories/auth_repository_impl_test.dart  # Repository unit tests
│   │       ├── domain/usecases/login_usecase_test.dart           # UseCase unit tests
│   │       └── presentation/
│   │           ├── bloc/login_bloc_test.dart                     # BLoC unit tests
│   │           └── pages/login_page_test.dart                    # Widget tests
│   └── widget_test.dart
│
└── integration_test/
    └── auth/
        └── login_flow_test.dart           # Full end-to-end login flow test
```

---

## The Three Layers Explained

### Layer 1 — Domain (The Brain)

**Location:** `lib/features/<feature>/domain/`

This is the most important layer. It contains your business rules and is completely independent — no Flutter, no Dio, no AWS SDK.

```
domain/
├── entities/      → Pure Dart data objects (what a "User" means in this app)
├── repositories/  → Abstract interfaces (contracts only, no implementation)
└── usecases/      → Single-purpose business actions (LoginUseCase, LogoutUseCase)
```

**Why entities and not just JSON models?**
If AWS Cognito is replaced with Firebase tomorrow, the `UserEntity` does not change. Only the Data layer changes. The rest of the app never knows.

**UserEntity** — pure Dart, no external imports:
```dart
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String accessToken;
  // No fromJson, no toJson — that belongs in UserModel (Data layer)
}
```

**AuthRepository** — defines the contract, not the implementation:
```dart
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({required String email, required String password});
  Future<Either<Failure, void>> logout();
}
```

**LoginUseCase** — one class, one job:
```dart
class LoginUseCase {
  Future<Either<Failure, UserEntity>> call(LoginParams params) {
    // Validates input, then delegates to repository
    return repository.login(email: params.email, password: params.password);
  }
}
```

---

### Layer 2 — Data (The Hands)

**Location:** `lib/features/<feature>/data/`

This layer knows how to actually fetch and store data. It implements the domain repository contracts.

```
data/
├── datasources/   → Remote (API/AWS) and Local (cache) data sources
├── models/        → Extend entities and add JSON serialization
└── repositories/  → Implement domain repository interfaces
```

**UserModel** — extends the entity and adds JSON:
```dart
class UserModel extends UserEntity {
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['sub'], email: json['email'], ...);
  }
  Map<String, dynamic> toJson() => {'id': id, 'email': email, ...};
}
```

**AuthRepositoryImpl** — bridges domain and data. Catches exceptions, returns Failures:
```dart
Future<Either<Failure, UserEntity>> login({...}) async {
  try {
    final user = await remoteDataSource.login(email: email, password: password);
    await localDataSource.cacheUser(user);   // Cache on success
    return Right(user);
  } on AuthException catch (e) {
    return Left(AuthFailure(e.message));     // Convert exception → Failure
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

---

### Layer 3 — Presentation (The Face)

**Location:** `lib/features/<feature>/presentation/`

This layer builds the UI and manages state with BLoC. It never touches the API or database directly.

```
presentation/
├── bloc/    → Events (user actions) + States (UI conditions) + Bloc (logic)
├── pages/   → Full screens
└── widgets/ → Reusable UI components for this feature
```

---

## Data Flow — Step by Step

Here is exactly what happens when a user taps the Login button:

```
1. User fills in email + password and taps "Login"
        │
        ▼
2. LoginForm calls onSubmit(email, password)
        │
        ▼
3. LoginPage dispatches LoginSubmitted event to LoginBloc
   context.read<LoginBloc>().add(LoginSubmitted(...))
        │
        ▼
4. LoginBloc emits LoginLoading → UI shows spinner
        │
        ▼
5. LoginBloc calls LoginUseCase(LoginParams(email, password))
        │
        ▼
6. LoginUseCase validates input, then calls AuthRepository.login()
        │
        ▼
7. AuthRepositoryImpl calls AuthRemoteDataSource.login()
        │
        ▼
8. AuthRemoteDataSource sends POST request to AWS Cognito endpoint
        │
    ┌───┴───────────────────────────────┐
    │ Success                           │ Failure
    ▼                                   ▼
9a. Repository caches user locally   9b. Exception is caught
    Returns Right(UserEntity)             Returns Left(AuthFailure)
        │                                   │
        ▼                                   ▼
10a. Bloc emits LoginSuccess          10b. Bloc emits LoginFailure
        │                                   │
        ▼                                   ▼
11a. UI navigates to HomePage         11b. UI shows error SnackBar
```

---

## State Management with BLoC

BLoC (Business Logic Component) separates user actions from UI state.

### Events — What can happen
```dart
// User tapped the login button
class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;
}

// User tapped logout
class LoginLogoutRequested extends LoginEvent {}
```

### States — What the UI can look like
```dart
class LoginInitial    extends LoginState {}  // Form is ready
class LoginLoading    extends LoginState {}  // Spinner showing
class LoginSuccess    extends LoginState { final UserEntity user; }
class LoginFailure    extends LoginState { final String message; }
class LoginLoggingOut extends LoginState {}
```

### Bloc — Connects events to states
```dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.loginUseCase, required this.logoutUseCase})
      : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter emit) async {
    emit(LoginLoading());
    final result = await loginUseCase(LoginParams(...));
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user)    => emit(LoginSuccess(user)),
    );
  }
}
```

### UI reacts to state
```dart
BlocConsumer<LoginBloc, LoginState>(
  listener: (context, state) {
    if (state is LoginSuccess) Navigator.pushReplacementNamed(context, '/home');
    if (state is LoginFailure) showSnackBar(state.message);
  },
  builder: (context, state) {
    return LoginForm(
      isLoading: state is LoginLoading,
      onSubmit: (email, password) =>
          context.read<LoginBloc>().add(
            LoginSubmitted(email: email, password: password),
          ),
    );
  },
);
```

---

## Dependency Injection

**Location:** `lib/core/di/injection_container.dart`

GetIt is used as a service locator. All dependencies are registered once in `main()` before the app runs.

```dart
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Singletons — created once, reused everywhere
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Factory — new instance every time (important for BLoCs)
  sl.registerFactory(
    () => LoginBloc(loginUseCase: sl(), logoutUseCase: sl()),
  );
}
```

**In main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}
```

**Why `registerFactory` for BLoC?**
Each screen needs its own fresh BLoC instance with clean state. A singleton BLoC would carry stale state from previous screens.

---

## Network Layer

**Location:** `lib/core/network/`

Dio is configured centrally with three interceptors that run on every request automatically.

```
Every HTTP Request
      │
      ▼
AuthInterceptor       → Reads JWT from cache, adds Authorization header
      │
      ▼
(Request sent to server)
      │
      ▼
ErrorInterceptor      → On error: converts HTTP status codes to typed exceptions
      │
      ▼
LoggingInterceptor    → Prints request/response to console (debug mode only)
```

**AuthInterceptor** attaches the token automatically:
```dart
options.headers['Authorization'] = 'Bearer ${await tokenProvider()}';
```

**ErrorInterceptor** normalizes all HTTP errors into readable messages:
```dart
final message = switch (statusCode) {
  400 => 'Bad request.',
  401 => 'Session expired. Please log in again.',
  403 => 'You do not have permission.',
  500 => 'Server error. Please try again later.',
  _   => 'An unexpected error occurred.',
};
```

On a 401 response, the `AuthInterceptor` flags the session as expired so the app can redirect the user to the login screen.

---

## AWS Cognito Integration

**Location:** `lib/features/auth/data/datasources/auth_remote_datasource.dart`

Two options are provided. Choose one based on your project setup.

### Option A — Amplify Flutter SDK (Recommended for production)

Enable by adding to `pubspec.yaml`:
```yaml
dependencies:
  amplify_flutter: ^2.5.0
  amplify_auth_cognito: ^2.5.0
```

Then configure in `main.dart`:
```dart
await Amplify.addPlugin(AmplifyAuthCognito());
await Amplify.configure(amplifyconfig);  // Generated from `amplify pull`
```

The commented-out implementation in `auth_remote_datasource.dart` is ready to uncomment.

### Option B — Direct Cognito REST API (No Amplify SDK, currently active)

Uses Cognito's `InitiateAuth` endpoint directly via Dio.

```
POST https://cognito-idp.{region}.amazonaws.com/
Headers:
  Content-Type: application/x-amz-json-1.1
  X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth
Body:
  {
    "AuthFlow": "USER_PASSWORD_AUTH",
    "ClientId": "YOUR_APP_CLIENT_ID",
    "AuthParameters": { "USERNAME": "email", "PASSWORD": "password" }
  }
```

**To connect your AWS Cognito pool**, update these two constants in `auth_remote_datasource.dart`:
```dart
static const String _cognitoRegion = 'us-east-1';          // Your AWS region
static const String _clientId      = 'YOUR_CLIENT_ID';     // From AWS Console
```

### Token Storage Flow

```
Login success
    │
    ▼
AccessToken + IdToken returned by Cognito
    │
    ▼
Cached in SharedPreferences via AuthLocalDataSource
    │
    ▼
AuthInterceptor reads token on every outgoing API request
    │
    ▼
On 401 response: token cleared, user redirected to login
```

> **Security note:** For production, replace `SharedPreferences` with
> `flutter_secure_storage` to encrypt tokens at rest on the device.

---

## Error Handling

The app uses a two-level error system to keep concerns separated.

### Level 1 — Exceptions (Data layer only)

Thrown inside datasources when something goes wrong with the external system:

| Exception | When thrown |
|-----------|-------------|
| `ServerException` | API returned a non-2xx status |
| `AuthException` | Cognito rejected the credentials |
| `NetworkException` | No internet connection |
| `CacheException` | SharedPreferences read/write failed |

### Level 2 — Failures (Domain and Presentation)

Returned by repositories. The Presentation layer only ever sees Failures, never raw exceptions:

| Failure | Cause |
|---------|-------|
| `ServerFailure` | API error |
| `AuthFailure` | Authentication rejected |
| `NetworkFailure` | No internet |
| `CacheFailure` | Local storage error |

### Either — Success or Failure, never both

```dart
// Either<Failure, UserEntity>
//   Left  = failure (something went wrong)
//   Right = success (data returned)

result.fold(
  (failure) => emit(LoginFailure(failure.message)),  // Left branch
  (user)    => emit(LoginSuccess(user)),              // Right branch
);
```

This forces every caller to handle both cases explicitly. There are no uncaught exceptions reaching the UI.

---

## Testing

### Test Coverage — 18 Tests, All Passing

```
test/
├── features/auth/
│   ├── domain/usecases/login_usecase_test.dart           4 unit tests
│   ├── data/repositories/auth_repository_impl_test.dart  4 unit tests
│   └── presentation/
│       ├── bloc/login_bloc_test.dart                     4 unit tests
│       └── pages/login_page_test.dart                    5 widget tests
└── widget_test.dart                                      1 placeholder

integration_test/auth/login_flow_test.dart                3 integration tests
```

### Unit Tests — UseCase

Tests that business rules work correctly regardless of what the repository does.

```dart
test('returns AuthFailure immediately when email is empty', () async {
  final result = await useCase(LoginParams(email: '', password: 'pass123'));

  // UseCase validates BEFORE calling the repository
  expect(result, Left(AuthFailure('Email and password cannot be empty.')));
  verifyNever(() => mockRepository.login(...));  // Repository never called
});
```

### Unit Tests — BLoC

Tests that state transitions are emitted in the correct order.

```dart
blocTest<LoginBloc, LoginState>(
  'emits [LoginLoading, LoginSuccess] when login succeeds',
  build: () {
    when(() => mockLoginUseCase(any())).thenAnswer((_) async => Right(testUser));
    return loginBloc;
  },
  act: (bloc) => bloc.add(LoginSubmitted(email: 'test@test.com', password: 'pass')),
  expect: () => [LoginLoading(), LoginSuccess(testUser)],
);
```

### Unit Tests — Repository

Tests that exceptions from the datasource are correctly converted to Failures.

```dart
test('returns AuthFailure when AuthException is thrown', () async {
  when(() => mockRemote.login(...))
      .thenAnswer((_) => Future.error(AuthException('Incorrect password.')));

  final result = await repository.login(email: '...', password: '...');

  expect(result, Left(AuthFailure('Incorrect password.')));
  verifyNever(() => mockLocal.cacheUser(any()));  // Not cached on failure
});
```

### Widget Tests — UI + BLoC

Tests that the UI renders correctly for each state and dispatches the right events.

```dart
testWidgets('dispatches LoginSubmitted when form is submitted', (tester) async {
  when(() => mockLoginBloc.state).thenReturn(LoginInitial());
  await tester.pumpWidget(buildTestWidget());

  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'pass123');
  await tester.tap(find.byKey(Key('login_button')));

  verify(() => mockLoginBloc.add(
    LoginSubmitted(email: 'test@example.com', password: 'pass123'),
  )).called(1);
});
```

### Run Tests

```bash
# Unit + Widget tests
flutter test test/

# Integration tests (requires device or emulator)
flutter test integration_test/
```

---

## How to Add a New Feature

Follow these steps to add, for example, a `profile` feature:

**1. Create the folder structure:**
```
lib/features/profile/
├── data/
│   ├── datasources/profile_remote_datasource.dart
│   ├── models/profile_model.dart
│   └── repositories/profile_repository_impl.dart
├── domain/
│   ├── entities/profile_entity.dart
│   ├── repositories/profile_repository.dart
│   └── usecases/get_profile_usecase.dart
└── presentation/
    ├── bloc/profile_bloc.dart
    ├── pages/profile_page.dart
    └── widgets/
```

**2. Define the entity** (pure Dart, no imports):
```dart
class ProfileEntity extends Equatable {
  final String userId;
  final String fullName;
  final String? avatarUrl;
}
```

**3. Define the repository contract:**
```dart
abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile(String userId);
}
```

**4. Write the UseCase:**
```dart
class GetProfileUseCase implements UseCase<ProfileEntity, String> {
  Future<Either<Failure, ProfileEntity>> call(String userId) {
    return repository.getProfile(userId);
  }
}
```

**5. Register in `injection_container.dart`:**
```dart
sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(remote: sl()));
sl.registerLazySingleton(() => GetProfileUseCase(sl()));
sl.registerFactory(() => ProfileBloc(getProfile: sl()));
```

**6. Write tests** in `test/features/profile/` — same pattern as auth.

That is all. No other file needs to change.

---

## Running the App

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run all unit + widget tests
flutter test test/

# Run integration tests (requires connected device or emulator)
flutter test integration_test/

# Analyze for lint issues
flutter analyze

# Check for outdated packages
flutter pub outdated
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^8.1.6 | BLoC state management |
| `bloc` | ^8.1.4 | Core BLoC library |
| `dartz` | ^0.10.1 | Either type for functional error handling |
| `dio` | ^5.7.0 | HTTP client with interceptors |
| `get_it` | ^8.0.0 | Dependency injection service locator |
| `equatable` | ^2.0.5 | Value equality for entities and states |
| `shared_preferences` | ^2.3.4 | Local token caching |
| `bloc_test` | ^9.1.7 | BLoC-specific test utilities |
| `mocktail` | ^1.0.4 | Type-safe mocking |
| `integration_test` | SDK | End-to-end testing |

**Optional (AWS Amplify):**

| Package | Version | Purpose |
|---------|---------|---------|
| `amplify_flutter` | ^2.5.0 | AWS Amplify SDK |
| `amplify_auth_cognito` | ^2.5.0 | Cognito auth via Amplify |

---

## Architecture Principles Summary

| Principle | How It Is Applied |
|-----------|------------------|
| **Separation of Concerns** | Each class has one job. UI never calls API. Domain never imports Flutter. |
| **Dependency Inversion** | Domain defines interfaces. Data implements them. Presentation consumes them. |
| **Single Responsibility** | One UseCase per business action. One BLoC per feature. |
| **Testability** | Every class receives its dependencies — swap real with mock in tests. |
| **Scalability** | Add a new feature by adding a new folder under `features/`. Nothing else changes. |
| **Fail Explicitly** | `Either<Failure, T>` forces every caller to handle both success and failure. No silent errors. |