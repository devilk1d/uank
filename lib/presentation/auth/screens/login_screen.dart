import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../repository_providers.dart';

enum _AuthView {
  landing,
  login,
  signup,
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthView _currentView = _AuthView.landing;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchView(_AuthView view) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentView = view;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      if (_currentView == _AuthView.signup) {
        await authRepo.signUp(
          email: email,
          password: password,
          data: name.isNotEmpty ? {'full_name': name} : null,
        );
      } else {
        await authRepo.signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);
    final isExpanded = _currentView != _AuthView.landing;
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
                    Colors.black.withValues(alpha: isExpanded ? 0.75 : 0.65),
                    Colors.black.withValues(alpha: isExpanded ? 0.95 : 0.9),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. ANIMATED BLUR & DIM OVERLAY (Active when Login / Signup is expanded)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isExpanded ? 7.0 : 0.0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.fastOutSlowIn,
              builder: (context, blurSigma, child) {
                if (blurSigma <= 0.05) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _switchView(_AuthView.landing);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: (blurSigma / 7.0) * 0.25),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. ANIMATED BOTTOM SHEET MODAL
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.fastOutSlowIn,
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * (isExpanded ? 0.82 : 0.44) + bottomInset,
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
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isExpanded
                      ? _buildFormView(context, isDark, primaryAccent, bottomInset, bottomPadding)
                      : _buildLandingView(context, isDark, primaryAccent),
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
              'lib/core/image/uanktext2.png',
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
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
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

  // --- 2. EXPANDED FORM VIEW (Login / Signup) ---
  Widget _buildFormView(BuildContext context, bool isDark, Color primaryAccent, double bottomInset, double bottomPadding) {
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

            // Full Name (Only on Sign Up)
            if (isSignUp) ...[
              Text(
                'Name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: _buildInputDecoration(
                  context: context,
                  isDark: isDark,
                  primaryAccent: primaryAccent,
                  hintText: 'e.g. Alex Smith',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (value) {
                  if (isSignUp && (value == null || value.trim().isEmpty)) {
                    return 'Name is required';
                  }
                  return null;
                },
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
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

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
}

