import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_app_architecture/features/auth/presentation/bloc/login_bloc.dart';
import 'package:flutter_app_architecture/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app_architecture/features/auth/presentation/widgets/login_form.dart';

// MockBloc for widget testing — does not run real logic
class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

void main() {
  late MockLoginBloc mockLoginBloc;

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    accessToken: 'token-abc',
  );

  setUp(() {
    mockLoginBloc = MockLoginBloc();
    registerFallbackValue(
      const LoginSubmitted(email: '', password: ''),
    );
  });

  // Helper that wraps the widget with required providers
  Widget buildTestWidget() {
    return MaterialApp(
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home Screen')),
      },
      home: BlocProvider<LoginBloc>.value(
        value: mockLoginBloc,
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage widget tests', () {
    testWidgets('shows LoginForm when state is LoginInitial', (tester) async {
      when(() => mockLoginBloc.state).thenReturn(const LoginInitial());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is LoginLoading',
        (tester) async {
      when(() => mockLoginBloc.state).thenReturn(const LoginLoading());

      await tester.pumpWidget(buildTestWidget());

      // Button is disabled while loading (no CircularProgressIndicator in page itself)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dispatches LoginSubmitted when form is submitted',
        (tester) async {
      when(() => mockLoginBloc.state).thenReturn(const LoginInitial());

      await tester.pumpWidget(buildTestWidget());

      // Fill in the form
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'pass123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // Verify the correct event was added to the BLoC
      verify(() => mockLoginBloc.add(
            const LoginSubmitted(
              email: 'test@example.com',
              password: 'pass123',
            ),
          )).called(1);
    });

    testWidgets('navigates to /home when LoginSuccess is emitted',
        (tester) async {
      whenListen(
        mockLoginBloc,
        Stream.fromIterable([
          const LoginLoading(),
          const LoginSuccess(testUser),
        ]),
        initialState: const LoginInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('shows snackbar when LoginFailure is emitted', (tester) async {
      whenListen(
        mockLoginBloc,
        Stream.fromIterable([
          const LoginLoading(),
          const LoginFailure('Incorrect username or password.'),
        ]),
        initialState: const LoginInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Incorrect username or password.'), findsOneWidget);
    });
  });
}