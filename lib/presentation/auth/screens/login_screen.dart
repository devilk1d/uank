import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/widgets/legal_document_sheet.dart';
import '../../repository_providers.dart';
import '../providers/auth_providers.dart';

enum _AuthView {
  landing,
  login,
  signup,
  verifyOtp,
  signupSuccess,
  loginSuccess,
  forgotPasswordEmail,
  forgotPasswordOtp,
  forgotPasswordNewPassword,
  forgotPasswordSuccess,
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  Timer? _successTimer;

  late final AnimationController _formSlideController;
  late final Animation<Offset> _formSlideAnimation;

  _AuthView _currentView = _AuthView.landing;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  void initState() {
    super.initState();
    _formSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formSlideController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _resendTimer?.cancel();
    _formSlideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  void _switchView(_AuthView view) {
    HapticFeedback.selectionClick();
    _successTimer?.cancel();
    if (view == _AuthView.landing || view == _AuthView.login || view == _AuthView.signup) {
      ref.read(passwordRecoveryModeProvider.notifier).setMode(false);
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
    }
    if (view == _AuthView.landing) {
      FocusScope.of(context).unfocus();
      _formSlideController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentView = _AuthView.landing;
            _errorMessage = null;
          });
        }
      });
    } else {
      setState(() {
        _currentView = view;
        _errorMessage = null;
      });
      _formSlideController.forward();
    }
  }

  void _startSuccessTransition(_AuthView successView, {Duration delay = const Duration(milliseconds: 1400), required VoidCallback onComplete}) {
    _successTimer?.cancel();
    _resendTimer?.cancel();
    setState(() {
      _currentView = successView;
      _isLoading = false;
      _errorMessage = null;
    });

    _successTimer = Timer(delay, () {
      if (!mounted) return;
      onComplete();
    });
  }

  void _completeAuthTransition() {
    _successTimer?.cancel();
    ref.read(passwordRecoveryModeProvider.notifier).setMode(false);
    ref.read(authTransitionLockProvider.notifier).setLocked(false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_currentView == _AuthView.signup) {
        await authRepo.signUp(
          email: email,
          password: password,
        );
        // Switch to OTP verification view with countdown
        if (mounted) {
          setState(() {
            _currentView = _AuthView.verifyOtp;
            _errorMessage = null;
            _otpController.clear();
          });
          _startResendTimer();
        }
      } else {
        ref.read(authTransitionLockProvider.notifier).setLocked(true);
        await authRepo.signIn(email: email, password: password);
        if (mounted) {
          _startSuccessTransition(
            _AuthView.loginSuccess,
            delay: const Duration(milliseconds: 1400),
            onComplete: _completeAuthTransition,
          );
        }
      }
    } on AuthException catch (e) {
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
      if (mounted) setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted && _currentView != _AuthView.loginSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtpSubmit() async {
    final email = _emailController.text.trim();
    final token = _otpController.text.trim();
    if (token.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit confirmation code');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ref.read(authTransitionLockProvider.notifier).setLocked(true);
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyOtp(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      if (mounted) {
        _startSuccessTransition(
          _AuthView.signupSuccess,
          delay: const Duration(milliseconds: 1400),
          onComplete: _completeAuthTransition,
        );
      }
    } on AuthException catch (e) {
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
      if (mounted) setState(() => _errorMessage = 'Invalid or expired confirmation code. Please try again.');
    } finally {
      if (mounted && _currentView != _AuthView.signupSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    final email = _emailController.text.trim();
    setState(() => _errorMessage = null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resendOtp(
        email: email,
        type: OtpType.signup,
      );
      _startResendTimer();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to resend confirmation code. Please try again.');
    }
  }

  Future<void> _sendForgotPasswordEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPasswordForEmail(email);
      if (mounted) {
        setState(() {
          _currentView = _AuthView.forgotPasswordOtp;
          _otpController.clear();
        });
        _startResendTimer();
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to send recovery code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendForgotPasswordOtp() async {
    if (!_canResend) return;
    final email = _emailController.text.trim();
    setState(() => _errorMessage = null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPasswordForEmail(email);
      _startResendTimer();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Failed to resend recovery code. Please try again.');
    }
  }

  Future<void> _verifyForgotPasswordOtpSubmit() async {
    final email = _emailController.text.trim();
    final token = _otpController.text.trim();
    if (token.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit recovery code');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ref.read(passwordRecoveryModeProvider.notifier).setMode(true);
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyOtp(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      if (mounted) {
        setState(() {
          _currentView = _AuthView.forgotPasswordNewPassword;
          _newPasswordController.clear();
          _confirmNewPasswordController.clear();
        });
      }
    } on AuthException catch (e) {
      ref.read(passwordRecoveryModeProvider.notifier).setMode(false);
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      ref.read(passwordRecoveryModeProvider.notifier).setMode(false);
      if (mounted) setState(() => _errorMessage = 'Invalid or expired recovery code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateForgotPasswordSubmit() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmNewPasswordController.text;

    final validationError = PasswordValidator.validate(newPass);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ref.read(authTransitionLockProvider.notifier).setLocked(true);
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updatePassword(newPass);
      if (mounted) {
        _startSuccessTransition(
          _AuthView.forgotPasswordSuccess,
          delay: const Duration(milliseconds: 1400),
          onComplete: _completeAuthTransition,
        );
      }
    } on AuthException catch (e) {
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      ref.read(authTransitionLockProvider.notifier).setLocked(false);
      if (mounted) setState(() => _errorMessage = 'Failed to update password. Please try again.');
    } finally {
      if (mounted && _currentView != _AuthView.forgotPasswordSuccess) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE (phone1.png)
          Positioned.fill(
            child: Image.asset(
              'lib/core/image/phone1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0E0E10),
              ),
            ),
          ),

          // 2. GRADIENT OVERLAY (Dimming for readability & seamless bottom blend)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. ANIMATED BLUR & DIM OVERLAY (Synchronized with slide-in form)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _formSlideController,
              builder: (context, child) {
                final progress = _formSlideController.value;
                if (progress <= 0.01) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => _switchView(_AuthView.landing),
                  behavior: HitTestBehavior.opaque,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 7.0 * progress,
                        sigmaY: 7.0 * progress,
                      ),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.35 * progress),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. LANDING BOTTOM SHEET MODAL (Stays fixed in place at the bottom, fades out when form slides in)
          AnimatedBuilder(
            animation: _formSlideController,
            builder: (context, child) {
              final opacity = (1.0 - _formSlideController.value * 2.0).clamp(0.0, 1.0);
              if (opacity <= 0.0) return const SizedBox.shrink();
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141418) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: _buildLandingView(context, isDark, primaryAccent),
                ),
              ),
            ),
          ),

          // 5. EXPANDED LOGIN / SIGNUP FORM MODAL (Slides in from the bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _formSlideAnimation,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.84 + bottomInset,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141418) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: _buildFormView(context, isDark, primaryAccent, bottomInset, bottomPadding),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. LANDING VIEW (Logo, Subtitle, Log in & Sign up buttons + Terms) ---
  Widget _buildLandingView(BuildContext context, bool isDark, Color primaryAccent) {
    return Padding(
      key: const ValueKey('landing_view'),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Brand Logo inside modal container
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'lib/core/image/uanktext3.png',
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'uank',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle inside modal
          Text(
            'Smart wealth management, made simple.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: isDark ? const Color(0xFF9E9EA8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Button: Log in
          GestureDetector(
            onTap: () => _switchView(_AuthView.login),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(26),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Log in',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Button: Sign up
          GestureDetector(
            onTap: () => _switchView(_AuthView.signup),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  'Sign up',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Terms & Privacy Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text.rich(
              TextSpan(
                text: 'By continuing, you agree to UANK\'s\n',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        HapticFeedback.lightImpact();
                        LegalDocumentSheet.showPrivacyPolicy(context);
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        HapticFeedback.lightImpact();
                        LegalDocumentSheet.showTermsOfService(context);
                      },
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. EXPANDED FORM VIEW (Login / Signup / Verify OTP) ---
  Widget _buildFormView(BuildContext context, bool isDark, Color primaryAccent, double bottomInset, double bottomPadding) {
    if (_currentView == _AuthView.verifyOtp) {
      return _buildOtpVerificationView(context, isDark, primaryAccent, bottomInset, bottomPadding);
    }
    if (_currentView == _AuthView.signupSuccess) {
      return _buildSuccessCardView(
        context: context,
        isDark: isDark,
        primaryAccent: primaryAccent,
        title: 'Account Verified!',
        subtitle: 'Your account is active and secure. Entering your workspace...',
        bottomInset: bottomInset,
        bottomPadding: bottomPadding,
      );
    }
    if (_currentView == _AuthView.loginSuccess) {
      return _buildSuccessCardView(
        context: context,
        isDark: isDark,
        primaryAccent: primaryAccent,
        title: 'Welcome Back!',
        subtitle: 'Signed in successfully. Entering your dashboard...',
        bottomInset: bottomInset,
        bottomPadding: bottomPadding,
      );
    }
    if (_currentView == _AuthView.forgotPasswordEmail) {
      return _buildForgotPasswordEmailView(context, isDark, primaryAccent, bottomInset, bottomPadding);
    }
    if (_currentView == _AuthView.forgotPasswordOtp) {
      return _buildForgotPasswordOtpView(context, isDark, primaryAccent, bottomInset, bottomPadding);
    }
    if (_currentView == _AuthView.forgotPasswordNewPassword) {
      return _buildForgotPasswordNewPasswordView(context, isDark, primaryAccent, bottomInset, bottomPadding);
    }
    if (_currentView == _AuthView.forgotPasswordSuccess) {
      return _buildSuccessCardView(
        context: context,
        isDark: isDark,
        primaryAccent: primaryAccent,
        title: 'Password Updated',
        subtitle: 'Your account password has been successfully changed. Entering your dashboard...',
        bottomInset: bottomInset,
        bottomPadding: bottomPadding,
      );
    }

    final isSignUp = _currentView == _AuthView.signup;

    return SingleChildScrollView(
      key: ValueKey('form_view_${isSignUp ? "signup" : "login"}'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Modal Header Row (Back Button + Centered Title)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _switchView(_AuthView.landing),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                Text(
                  isSignUp ? 'Sign Up' : 'Log In',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 36), // Balanced spacing
              ],
            ),
            const SizedBox(height: 18),

            // Heading & Subtitle
            Text(
              isSignUp ? 'Create your account' : 'Welcome back',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSignUp
                  ? 'Start managing your multi-currency wealth'
                  : 'Enter your credentials to continue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            // Error Alert Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Email Field
            Text(
              'Email address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: _buildInputDecoration(
                context: context,
                isDark: isDark,
                primaryAccent: primaryAccent,
                hintText: 'name@example.com',
                prefixIcon: Icons.alternate_email_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password Field
            Text(
              'Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: _buildInputDecoration(
                context: context,
                isDark: isDark,
                primaryAccent: primaryAccent,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (isSignUp) {
                  return PasswordValidator.validate(value);
                } else {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                }
              },
            ),
            if (isSignUp) ...[
              const SizedBox(height: 6),
              Text(
                'Min. 6 chars with uppercase, lowercase & symbol (=, -, @, #, etc.)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],

            // Forgot Password Link (Only on Log In)
            if (!isSignUp) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _switchView(_AuthView.forgotPasswordEmail);
                  },
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ),
            ],

            // Confirm Password Field (Only on Sign Up)
            if (isSignUp) ...[
              const SizedBox(height: 14),
              Text(
                'Confirm Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: _buildInputDecoration(
                  context: context,
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_reset_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (isSignUp) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 22),

            // Continue Button (Pill style)
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _submit();
                    },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                          ),
                        )
                      : Text(
                          isSignUp ? 'Create Account' : 'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mode Switcher Footer Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                GestureDetector(
                  onTap: () => _switchView(isSignUp ? _AuthView.login : _AuthView.signup),
                  child: Text(
                    isSignUp ? 'Log in' : 'Sign up',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. OTP VERIFICATION VIEW (6-Digit Confirmation Code) ---
  Widget _buildOtpVerificationView(
    BuildContext context,
    bool isDark,
    Color primaryAccent,
    double bottomInset,
    double bottomPadding,
  ) {
    final email = _emailController.text.trim();
    final otpText = _otpController.text;

    return SingleChildScrollView(
      key: const ValueKey('form_view_verify_otp'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Modal Header Row (Back Button + Centered Title)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  _resendTimer?.cancel();
                  _switchView(_AuthView.signup);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              Text(
                'Verification',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 20),

          // Heading & Subtitle
          Text(
            'Verify your email',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit confirmation code to\n'),
                TextSpan(
                  text: email.isNotEmpty ? email : 'your email address',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Error Alert Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6-Digit OTP Box Grid (Stacking invisible TextField + visual boxes)
          Stack(
            alignment: Alignment.center,
            children: [
              // Hidden real text field for keyboard handling
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (val) {
                      setState(() {});
                      if (val.length == 6) {
                        _verifyOtpSubmit();
                      }
                    },
                  ),
                ),
              ),

              // Visual 6-box row
              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final char = index < otpText.length ? otpText[index] : '';
                    final isCurrent = index == otpText.length;
                    final isFilled = index < otpText.length;

                    return Container(
                      width: 48,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1B22) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent
                              ? primaryAccent
                              : isFilled
                                  ? (isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF94A3B8))
                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                          width: isCurrent ? 1.8 : 1.2,
                        ),
                        boxShadow: isCurrent && isDark
                            ? [
                                BoxShadow(
                                  color: primaryAccent.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Resend Timer Row
          Center(
            child: _canResend
                ? GestureDetector(
                    onTap: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend confirmation code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryAccent,
                      ),
                    ),
                  )
                : Text(
                    'Resend code in ${_resendCountdown}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Primary Submit Button
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _verifyOtpSubmit();
                  },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(26),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      )
                    : Text(
                        'Verify & Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Change Email link
          Center(
            child: GestureDetector(
              onTap: () {
                _resendTimer?.cancel();
                _switchView(_AuthView.signup);
              },
              child: Text(
                'Wrong email? Edit email address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. FORGOT PASSWORD: EMAIL VIEW ---
  Widget _buildForgotPasswordEmailView(
    BuildContext context,
    bool isDark,
    Color primaryAccent,
    double bottomInset,
    double bottomPadding,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('form_view_forgot_password_email'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Modal Header Row (Back Button + Centered Title)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _switchView(_AuthView.login),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              Text(
                'Forgot Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 18),

          // Heading & Subtitle
          Text(
            'Reset your password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your registered email and we\'ll send a 6-digit recovery code to reset your password.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Error Alert Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Email Field
          Text(
            'Email address',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: _buildInputDecoration(
              context: context,
              isDark: isDark,
              primaryAccent: primaryAccent,
              hintText: 'name@example.com',
              prefixIcon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(height: 24),

          // Send Recovery Code Button
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _sendForgotPasswordEmail();
                  },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(26),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      )
                    : Text(
                        'Send Recovery Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Return to Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: () => _switchView(_AuthView.login),
                child: Text(
                  'Log in',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primaryAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. FORGOT PASSWORD: OTP VERIFICATION VIEW ---
  Widget _buildForgotPasswordOtpView(
    BuildContext context,
    bool isDark,
    Color primaryAccent,
    double bottomInset,
    double bottomPadding,
  ) {
    final email = _emailController.text.trim();
    final otpText = _otpController.text;

    return SingleChildScrollView(
      key: const ValueKey('form_view_forgot_password_otp'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Modal Header Row (Back Button + Centered Title)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  _resendTimer?.cancel();
                  _switchView(_AuthView.forgotPasswordEmail);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              Text(
                'Recovery Code',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 18),

          // Heading & Subtitle
          Text(
            'Enter recovery code',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: 'We\'ve sent a 6-digit recovery code to\n',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              children: [
                TextSpan(
                  text: email.isNotEmpty ? email : 'your email',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error Alert Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 6-BOX OTP INPUT
          Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (val) {
                      setState(() {});
                      if (val.length == 6) {
                        _verifyForgotPasswordOtpSubmit();
                      }
                    },
                  ),
                ),
              ),

              // Visual 6-box row
              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final char = index < otpText.length ? otpText[index] : '';
                    final isCurrent = index == otpText.length;
                    final isFilled = index < otpText.length;

                    return Container(
                      width: 48,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1B22) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent
                              ? primaryAccent
                              : isFilled
                                  ? (isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF94A3B8))
                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
                          width: isCurrent ? 1.8 : 1.2,
                        ),
                        boxShadow: isCurrent && isDark
                            ? [
                                BoxShadow(
                                  color: primaryAccent.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Resend Timer Row
          Center(
            child: _canResend
                ? GestureDetector(
                    onTap: _isLoading ? null : _resendForgotPasswordOtp,
                    child: Text(
                      'Resend recovery code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryAccent,
                      ),
                    ),
                  )
                : Text(
                    'Resend code in ${_resendCountdown}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Primary Submit Button
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _verifyForgotPasswordOtpSubmit();
                  },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(26),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      )
                    : Text(
                        'Verify & Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Edit email link
          Center(
            child: GestureDetector(
              onTap: () {
                _resendTimer?.cancel();
                _switchView(_AuthView.forgotPasswordEmail);
              },
              child: Text(
                'Wrong email? Edit email address',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. FORGOT PASSWORD: NEW PASSWORD VIEW ---
  Widget _buildForgotPasswordNewPasswordView(
    BuildContext context,
    bool isDark,
    Color primaryAccent,
    double bottomInset,
    double bottomPadding,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('form_view_forgot_password_new_password'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Modal Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 36),
              Text(
                'New Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 18),

          // Heading & Subtitle
          Text(
            'Create new password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your identity has been verified. Enter your new password below.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Error Alert Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // New Password Field
          Text(
            'New password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: _buildInputDecoration(
              context: context,
              isDark: isDark,
              primaryAccent: primaryAccent,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Min. 6 chars with uppercase, lowercase & symbol (=, -, @, #, etc.)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm New Password Field
          Text(
            'Confirm new password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmNewPasswordController,
            obscureText: _obscureConfirmNewPassword,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: _buildInputDecoration(
              context: context,
              isDark: isDark,
              primaryAccent: primaryAccent,
              hintText: '••••••••',
              prefixIcon: Icons.lock_reset_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscureConfirmNewPassword = !_obscureConfirmNewPassword),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Update Password Button
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _updateForgotPasswordSubmit();
                  },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(26),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required bool isDark,
    required Color primaryAccent,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 19,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1B1B22) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: primaryAccent,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
    );
  }

  Widget _buildSuccessCardView({
    required BuildContext context,
    required bool isDark,
    required Color primaryAccent,
    required String title,
    required String subtitle,
    required double bottomInset,
    required double bottomPadding,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 315),
      padding: EdgeInsets.fromLTRB(24, 14, 24, 18 + bottomInset + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Big Glowing Success Icon Circle (Same aesthetic as settings)
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryAccent.withValues(alpha: 0.15),
                border: Border.all(
                  color: primaryAccent.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}

