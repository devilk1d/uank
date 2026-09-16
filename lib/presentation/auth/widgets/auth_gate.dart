import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
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
      duration: const Duration(milliseconds: 320),
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
            return const AppSplashScreen(key: ValueKey('auth_refreshing'));
          } else {
            return const LoginScreen(key: ValueKey('login_screen'));
          }
        },
        loading: () => const AppSplashScreen(key: ValueKey('auth_loading')),
        error: (_, _) => const LoginScreen(key: ValueKey('login_screen_error')),
      ),
    );
  }
}

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.88, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Image.asset(
            'lib/core/image/uanktext2.png',
            width: 170,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'lib/core/image/uanktext.png',
              width: 170,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'uank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
