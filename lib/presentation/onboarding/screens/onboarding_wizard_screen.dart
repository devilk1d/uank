import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/step_all_set.dart';
import '../widgets/step_primary_account.dart';
import '../widgets/step_profile_avatar.dart';
import '../widgets/step_receipt_ocr.dart';
import '../widgets/step_recurring_bills.dart';
import '../widgets/step_starter_categories.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({
    super.key,
    this.initialStep = 0,
  });

  /// Allows launching directly to a specific step (useful for debugging and testing)
  final int initialStep;

  static Future<void> show(BuildContext context, {int initialStep = 0}) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingWizardScreen(initialStep: initialStep),
      ),
    );
  }

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  late final PageController _pageController;
  late int _currentStep;
  static const int _totalSetupSteps = 5; // Steps 1 to 5 (Step 6 is All Set celebration)

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, 5);
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_currentStep < 5) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previous() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);

    // Progress ranges from 0.20 on Step 1 to 1.0 on Step 5. Step 6 (All Set) hides the bar.
    final progress = _currentStep < _totalSetupSteps
        ? ((_currentStep + 1) / _totalSetupSteps).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation & Progress Bar
              if (_currentStep < 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (_currentStep > 0)
                            GestureDetector(
                              onTap: _previous,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.cardBg,
                                  border: Border.all(color: context.cardBorder),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 15,
                                  color: context.textPrimary,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 38, height: 38),
                          const Spacer(),
                          Image.asset(
                            'lib/core/image/uanktext3.png',
                            height: 22,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'lib/core/image/uanktext.png',
                              height: 22,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Text(
                                'uank',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: primaryAccent,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 38, height: 38),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Animated Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 4,
                          width: double.infinity,
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: primaryAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StepProfileAvatar(onNext: _next, onSkip: _next),
                    StepPrimaryAccount(onNext: _next, onSkip: _next),
                    StepStarterCategories(onNext: _next, onSkip: _next),
                    StepRecurringBills(onNext: _next, onSkip: _next),
                    StepReceiptOcr(onNext: _next, onSkip: _next),
                    const StepAllSet(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
