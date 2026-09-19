import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/app_initializer.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/screens/onboarding_wizard_screen.dart';
import '../../repository_providers.dart';
import '../../shell/responsive_shell.dart';
import '../providers/auth_providers.dart';
import '../screens/login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitializerProvider);
    final authStateAsync = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isRecovery = ref.watch(passwordRecoveryModeProvider);
    final transitionMode = ref.watch(authTransitionLockProvider);

    final Widget targetChild = initAsync.when(
      data: (_) {
        final authState = authStateAsync.value;
        if (authState != null) {
          final session = authState.session;

          // 1. If currently in exitingApp transition mode (logout / delete account),
          // keep ResponsiveShell mounted until transition completes.
          if (transitionMode == AuthTransitionMode.exitingApp) {
            return const ResponsiveShell(key: ValueKey('main_shell'));
          }

          // 2. If session is active and not in recovery mode
          if (session != null && !session.isExpired && !isRecovery) {
            // If enteringApp transition mode is active (login/signup success countdown on LoginScreen),
            // keep LoginScreen mounted until countdown completes.
            if (transitionMode == AuthTransitionMode.enteringApp) {
              return const LoginScreen(key: ValueKey('login_screen'));
            }

            final hasCompletedOnboarding = userProfile?.hasCompletedOnboarding ??
                ((session.user.userMetadata?['has_completed_onboarding'] as bool?) ?? true);

            if (hasCompletedOnboarding) {
              return const ResponsiveShell(key: ValueKey('main_shell'));
            } else {
              return const OnboardingWizardScreen(key: ValueKey('onboarding_wizard'));
            }
          } else if (session != null && session.isExpired && !isRecovery && transitionMode == AuthTransitionMode.none) {
            ref.read(authRepositoryProvider).refreshSessionIfNeeded();
            return const AppSplashScreen(key: ValueKey('app_splash'));
          } else {
            return const LoginScreen(key: ValueKey('login_screen'));
          }
        }

        if (authStateAsync.isLoading) {
          return const AppSplashScreen(key: ValueKey('app_splash'));
        }

        return const LoginScreen(key: ValueKey('login_screen'));
      },
      loading: () => const AppSplashScreen(key: ValueKey('app_splash')),
      error: (_, _) => const LoginScreen(key: ValueKey('login_screen')),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: targetChild,
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
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.90 + (0.10 * value),
                child: child,
              ),
            );
          },
          child: Image.asset(
            'lib/core/image/uanktext3.png',
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
