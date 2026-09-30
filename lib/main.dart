import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/services/notification_service.dart';
import 'package:lelahanoi/features/auth/data/auth_repository.dart';
import 'package:lelahanoi/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:lelahanoi/features/auth/presentation/pages/login_page.dart';
import 'package:lelahanoi/features/home/presentation/pages/main_page.dart';
import 'package:lelahanoi/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(
    BlocProvider(
      create: (_) => LanguageCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => AuthCubit(AuthRepository()),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final Widget home;
          switch (state.status) {
            case AuthStatus.authenticated:
              home = MainPage(isManager: state.isManager);
              break;
            case AuthStatus.checking:
              home = const _LoadingView();
              break;
            case AuthStatus.failure:
            case AuthStatus.unauthenticated:
              home = const LoginPage();
              break;
          }
          return _buildMaterialApp(home: home);
        },
      ),
    );
  }

  Widget _buildMaterialApp({required Widget home}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
