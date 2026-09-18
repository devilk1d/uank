import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class LegalSectionItem {
  final String title;
  final String content;
  final IconData? icon;

  const LegalSectionItem({
    required this.title,
    required this.content,
    this.icon,
  });
}

class LegalDocumentSheet extends StatelessWidget {
  const LegalDocumentSheet({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.summaryPoints,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<Map<String, dynamic>> summaryPoints;
  final List<LegalSectionItem> sections;

  static void showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LegalDocumentSheet(
        title: 'Privacy Policy',
        lastUpdated: 'September 2026',
        summaryPoints: [
          {
            'icon': Icons.security_rounded,
            'title': '100% Private & Confidential',
            'desc': 'We do not sell, rent, or trade your personal or financial data to anyone.',
          },
          {
            'icon': Icons.lock_outline_rounded,
            'title': 'Encrypted & Isolated',
            'desc': 'All communications are encrypted and your records are isolated strictly to your account.',
          },
          {
            'icon': Icons.delete_outline_rounded,
            'title': 'Account Deletion',
            'desc': 'You can permanently delete your account and all stored records directly in Settings.',
          },
        ],
        sections: [
          LegalSectionItem(
            title: '1. Privacy Commitment',
            content:
                'Welcome to UANK. Your financial records and personal data are strictly private. We do not sell, rent, or monetize your personal or financial information to third parties, data brokers, or advertisers.',
            icon: Icons.verified_user_outlined,
          ),
          LegalSectionItem(
            title: '2. Data We Collect',
            content:
                'We only collect the information necessary to provide the UANK tracking experience:\n• Account Information: Your email address, display name, and avatar image.\n• Financial Records: Accounts and wallets (cash, bank, e-wallet), transactions (expenses, incomes, transfers), custom categories, recurring bills, and saving goals.\n• Notification Data: Device push notification token (used exclusively for recurring bill reminders).',
            icon: Icons.folder_open_rounded,
          ),
          LegalSectionItem(
            title: '3. How We Use Your Data',
            content:
                'Your data is used solely to provide and operate the application:\n• Synchronizing your financial data securely to your account.\n• Calculating multi-currency totals, balances, and exchange rate conversions.\n• Sending timely reminders for upcoming recurring bills.\n• Visualizing your income and expense breakdowns.',
            icon: Icons.tune_rounded,
          ),
          LegalSectionItem(
            title: '4. Security & Data Protection',
            content:
                '• All data transmitted between your device and the cloud is encrypted using industry-standard HTTPS / TLS protocols.\n• Cloud database records are secured with authenticated access controls, ensuring that your records are strictly accessible only by your login credentials.',
            icon: Icons.shield_rounded,
          ),
          LegalSectionItem(
            title: '5. Third-Party Services',
            content:
                'We use cloud infrastructure and push notification services to reliably deliver the app features. Third-party exchange rate data is used solely to display currency conversion estimates and is not tied to your personal identity or account balances.',
            icon: Icons.cloud_done_outlined,
          ),
          LegalSectionItem(
            title: '6. Your Rights & Account Deletion',
            content:
                '• Access & Edit: You can add, edit, or remove your transactions, accounts, categories, and profile information at any time.\n• Account Deletion: You can permanently delete your account and all associated data at any time via Settings > Delete Account. Upon confirmation, your data is permanently removed.',
            icon: Icons.manage_accounts_outlined,
          ),
          LegalSectionItem(
            title: '7. Contact Us',
            content:
                'If you have any questions or feedback regarding this Privacy Policy, please contact us at support@uank.app.',
            icon: Icons.mail_outline_rounded,
          ),
        ],
      ),
    );
  }

  static void showTermsOfService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LegalDocumentSheet(
        title: 'Terms of Service',
        lastUpdated: 'September 2026',
        summaryPoints: [
          {
            'icon': Icons.account_balance_wallet_outlined,
            'title': 'Self-Tracking Tool',
            'desc': 'UANK is a personal expense tracking tool, not a bank or financial advisor.',
          },
          {
            'icon': Icons.handshake_outlined,
            'title': 'User Responsibility',
            'desc': 'You remain solely responsible for your own financial records and decisions.',
          },
          {
            'icon': Icons.currency_exchange_rounded,
            'title': 'Estimated Rates',
            'desc': 'Currency conversion rates are provided for estimation and reference purposes.',
          },
        ],
        sections: [
          LegalSectionItem(
            title: '1. Acceptance of Terms',
            content:
                'By accessing, registering, or using UANK, you agree to these Terms of Service. If you do not agree, please do not use the application.',
            icon: Icons.fact_check_outlined,
          ),
          LegalSectionItem(
            title: '2. Financial Disclaimer',
            content:
                'IMPORTANT NOTICE:\n• UANK is a manual tracking and wealth management software utility for personal use.\n• UANK is NOT a bank, licensed financial advisor, investment broker, or payment processor.\n• The charts, calculations, and information in the app do not constitute financial, legal, or investment advice. You are solely responsible for your own financial decisions.',
            icon: Icons.gavel_rounded,
          ),
          LegalSectionItem(
            title: '3. Currency Conversion Disclaimer',
            content:
                'Multi-currency values and exchange rates (such as IDR, MYR, USD) are provided for convenience and visual estimation. Rates may vary from real-time commercial bank rates. UANK is not liable for differences in actual transaction conversions.',
            icon: Icons.currency_exchange_rounded,
          ),
          LegalSectionItem(
            title: '4. Account Security',
            content:
                'You are responsible for keeping your login credentials and email verification codes secure. Please notify us if you notice any unauthorized access to your account.',
            icon: Icons.password_rounded,
          ),
          LegalSectionItem(
            title: '5. Acceptable Use',
            content:
                'You agree to use UANK for lawful personal finance tracking. You agree not to reverse engineer, disrupt the application infrastructure, or use the service for fraudulent activities.',
            icon: Icons.rule_rounded,
          ),
          LegalSectionItem(
            title: '6. Intellectual Property',
            content:
                'The UANK app, interface design, logos, and code are the intellectual property of UANK. You are granted a personal, non-exclusive license to use the app for personal expense tracking.',
            icon: Icons.copyright_rounded,
          ),
          LegalSectionItem(
            title: '7. Account Termination',
            content:
                'You can stop using UANK and delete your account at any time via Settings > Delete Account.',
            icon: Icons.person_remove_outlined,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;
    final cardBorder = context.cardBorder;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141418) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
            child: Column(
              children: [
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        title.contains('Privacy') ? Icons.verified_user_rounded : Icons.description_rounded,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Last Updated: $lastUpdated',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Document Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Points Highlights Card
                  if (summaryPoints.isNotEmpty) ...[
                    Text(
                      'KEY HIGHLIGHTS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: summaryPoints.map((point) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  point['icon'] as IconData,
                                  size: 18,
                                  color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point['title'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        point['desc'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Document Sections
                  Text(
                    'DETAILED CLAUSES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sections.map((section) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (section.icon != null) ...[
                                Icon(
                                  section.icon,
                                  size: 16,
                                  color: isDark ? AppColors.primaryLight : const Color(0xFF15803D),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            section.content,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom Close Action Button
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottomInset + bottomPadding),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141418) : Colors.white,
              border: Border(top: BorderSide(color: cardBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'I Understand & Close',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
