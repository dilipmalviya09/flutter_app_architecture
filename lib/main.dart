// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

Future<void> main() async {
  // Required before any async work before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Set up all dependencies (DI)
  await initDependencies();

  // If using AWS Amplify, configure it here:
  // await _configureAmplify();

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // LoginBloc is provided at root so HomePage can also dispatch LogoutRequested
        BlocProvider<LoginBloc>(create: (_) => sl<LoginBloc>()),
      ],
      child: MaterialApp(
        title: 'Flutter Clean Architecture',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: LoginPage.routeName,
        routes: {
          LoginPage.routeName: (_) => const LoginPage(),
          HomePage.routeName:  (_) => const HomePage(),
        },
      ),
    );
  }
}

// Future<void> _configureAmplify() async {
//   await Amplify.addPlugin(AmplifyAuthCognito());
//   await Amplify.configure(amplifyconfig);
// }