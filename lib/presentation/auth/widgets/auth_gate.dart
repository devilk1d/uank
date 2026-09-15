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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: authStateAsync.when(
        data: (authState) {
          final session = authState.session;
          if (session != null && !session.isExpired) {
            return const MainShell(key: ValueKey('main_shell'));
          } else if (session != null && session.isExpired) {
            // Token expired, attempt refresh
            ref.read(authRepositoryProvider).refreshSessionIfNeeded();
            return const Scaffold(
              key: ValueKey('auth_refreshing'),
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF10B981),
                ),
              ),
            );
          } else {
            return const LoginScreen(key: ValueKey('login_screen'));
          }
        },
        loading: () => const Scaffold(
          key: ValueKey('auth_loading'),
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        error: (_, _) => const LoginScreen(key: ValueKey('login_screen_error')),
      ),
    );
  }
}
