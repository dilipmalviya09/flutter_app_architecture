import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_app_architecture/main.dart' as app;

/// Integration test: verifies the full login UI flow end-to-end.
///
/// This test launches the real app (with real DI, real widgets).
/// For a real AWS Cognito test, replace credentials with test account values.
///
/// Run with: flutter test integration_test/auth/login_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow - Integration', () {
    testWidgets('shows login form on app start', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when form is submitted empty',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap login without filling in any fields
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('shows error snackbar on invalid credentials', (tester) async {
      // NOTE: This test requires a running backend or a stub server.
      // For CI: use a mock server (e.g., Wiremock or json-server).
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('email_field')), 'wrong@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'wrongpassword');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show an error snackbar (not navigate to home)
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    // Uncomment and configure test credentials to run a full login test:
    //
    // testWidgets('navigates to home screen on valid credentials', (tester) async {
    //   app.main();
    //   await tester.pumpAndSettle();
    //
    //   await tester.enterText(find.byKey(const Key('email_field')), 'test@yourapp.com');
    //   await tester.enterText(find.byKey(const Key('password_field')), 'TestPass123!');
    //   await tester.tap(find.byKey(const Key('login_button')));
    //   await tester.pumpAndSettle(const Duration(seconds: 10));
    //
    //   expect(find.text('You are logged in!'), findsOneWidget);
    // });
  });
}