import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository_providers.dart';
import '../../shell/main_shell.dart';
import '../providers/auth_providers.dart';
import '../screens/login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        final session = authState.session;
        if (session != null && !session.isExpired) {
          return const MainShell();
        } else if (session != null && session.isExpired) {
          // Token expired, attempt refresh
          ref.read(authRepositoryProvider).refreshSessionIfNeeded();
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF10B981),
              ),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF10B981),
          ),
        ),
      ),
      error: (_, _) => const LoginScreen(),
    );
  }
}
