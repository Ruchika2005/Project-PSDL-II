import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import '../../main/screens/main_screen.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangeProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
      loading: () => const SplashScreen(),
      error: (e, trace) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
