import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../repository_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

    try {
      if (_isSignUp) {
        await authRepo.signUp(email: email, password: password);
      } else {
        await authRepo.signIn(email: email, password: password);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Title
                    Text(
                      'uank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'Start managing your multi-currency finances'
                          : 'Sign in to your financial account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Main Glass Form Card
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.red.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: context.textSecondary,
                              ),
                              filled: true,
                              fillColor: context.inputBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: context.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: context.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide(
                                  color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: context.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: context.textSecondary,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: context.inputBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: context.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: context.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                borderSide: BorderSide(
                                  color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                                  width: 1.2,
                                ),
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
                          const SizedBox(height: 24),

                          // Submit Button
                          GestureDetector(
                            onTap: _isLoading ? null : _submit,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Sign Up' : 'Sign In',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toggle mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          }),
                          child: Text(
                            _isSignUp ? 'Sign In' : 'Sign Up Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.accentLinkColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
