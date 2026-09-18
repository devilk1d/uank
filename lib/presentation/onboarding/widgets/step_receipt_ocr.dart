import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/receipt_ocr_animation_widget.dart';
import '../../../core/widgets/smooth_app_switch.dart';
import '../../settings/providers/receipt_ocr_provider.dart';

class StepReceiptOcr extends ConsumerStatefulWidget {
  const StepReceiptOcr({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<StepReceiptOcr> createState() => _StepReceiptOcrState();
}

class _StepReceiptOcrState extends ConsumerState<StepReceiptOcr> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);
    final isOcrEnabled = ref.watch(receiptOcrSettingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Step Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: primaryAccent),
                          const SizedBox(width: 6),
                          Text(
                            'STEP 5 OF 5 \u00b7 SMART FEATURES',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title & Subtitle
                  Text(
                    'Smart Receipt Scanner',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Snap receipts or payment slips to auto-fill transaction amounts instantly using 100% on-device AI.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Moving Interactive Laser Scanner Graphic
                  const ReceiptOcrAnimationWidget(height: 195),
                  const SizedBox(height: 16),

                  // Main Switch Card
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isOcrEnabled
                                    ? primaryAccent
                                    : (isDark ? Colors.white12 : Colors.black12))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 20,
                            color: isOcrEnabled ? primaryAccent : textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Receipt Scanner',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOcrEnabled
                                    ? 'Auto-fill active for receipts & transfer slips'
                                    : 'Disabled (manual amount input only)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SmoothAppSwitch(
                          value: isOcrEnabled,
                          activeIcon: Icons.document_scanner_rounded,
                          inactiveIcon: Icons.crop_free_rounded,
                          onChanged: (val) {
                            ref.read(receiptOcrSettingProvider.notifier).setEnabled(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Highlights / Benefits List
                  _buildFeatureTile(
                    context,
                    icon: Icons.flash_on_rounded,
                    title: 'Instant Auto-Fill',
                    description: 'Extracts exact amounts, currency (IDR & MYR), and dates without manual typing.',
                    primaryAccent: primaryAccent,
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureTile(
                    context,
                    icon: Icons.shield_outlined,
                    title: '100% Private & On-Device',
                    description: 'Images are processed directly on your smartphone. Never sent to cloud AI.',
                    primaryAccent: primaryAccent,
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureTile(
                    context,
                    icon: Icons.tune_rounded,
                    title: 'Customizable in Settings',
                    description: 'You can toggle this scanner on or off anytime in Settings.',
                    primaryAccent: primaryAccent,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onNext();
                      },
                      child: Text(
                        isOcrEnabled ? 'Continue with Scanner' : 'Continue (Manual Entry)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(receiptOcrSettingProvider.notifier).setEnabled(false);
                      widget.onSkip();
                    },
                    child: Text(
                      'Skip for Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color primaryAccent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: primaryAccent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
