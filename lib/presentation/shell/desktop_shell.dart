import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_confirmation_sheet.dart';
import '../accounts/screens/accounts_screen.dart';
import '../auth/providers/auth_providers.dart';
import '../bills/providers/bill_providers.dart';
import '../bills/screens/bills_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../repository_providers.dart';
import '../saving_goals/screens/saving_goals_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../transactions/screens/add_transaction_sheet.dart';
import '../transactions/widgets/desktop_transaction_grid.dart';
import '../transfers/screens/add_transfer_sheet.dart';
import 'main_shell.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  static const _desktopScreens = [
    DashboardScreen(),
    DesktopTransactionGrid(),
    AccountsScreen(),
    BillsScreen(),
    SavingGoalsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final userProfile = ref.watch(userProfileProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    final bills = ref.watch(billsProvider).asData?.value ?? [];
    final payments = ref.watch(currentMonthBillPaymentsProvider).asData?.value ?? [];
    final activeBills = bills.where((b) => b.isActive).toList();
    final paidBillIds = payments.where((p) => p.status == 'paid').map((p) => p.billId).toSet();
    final unpaidBillsCount = activeBills.where((b) => !paidBillIds.contains(b.id)).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Row(
        children: [
          // 1. LEFT NAVIGATION SIDEBAR (Width: 260px)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF12141C) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A. App Branding Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'lib/core/image/applogo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.account_balance_wallet_rounded,
                              color: primaryAccent,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'uank',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'DESKTOP',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: primaryAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Finance & Multi-Currency',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // B. Quick Action Buttons (+ Transaction / + Transfer)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => AddTransactionSheet.show(context),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Add Tx'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryAccent,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => AddTransferSheet.show(context),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                          label: const Text('Transfer'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            foregroundColor: context.textPrimary,
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // C. Navigation Tabs List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    children: [
                      _SidebarNavItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isSelected: selectedIndex == 0,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(0),
                      ),
                      _SidebarNavItem(
                        icon: Icons.table_chart_rounded,
                        label: 'Transactions Grid',
                        isSelected: selectedIndex == 1,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(1),
                      ),
                      _SidebarNavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Accounts & Wallets',
                        isSelected: selectedIndex == 2,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(2),
                      ),
                      _SidebarNavItem(
                        icon: Icons.notifications_active_rounded,
                        label: 'Monthly Bills',
                        badgeCount: unpaidBillsCount,
                        isSelected: selectedIndex == 3,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(3),
                      ),
                      _SidebarNavItem(
                        icon: Icons.savings_rounded,
                        label: 'Saving Goals',
                        isSelected: selectedIndex == 4,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(4),
                      ),
                      _SidebarNavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: selectedIndex == 5,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(5),
                      ),
                    ],
                  ),
                ),

                // D. Sidebar Footer (User Profile Card + Logout Button)
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161822) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          avatarUrl: userProfile?.avatarUrl,
                          initialLetter: userProfile?.initialLetter ?? 'U',
                          size: 36,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (userProfile?.displayName != null && userProfile!.displayName.isNotEmpty)
                                    ? userProfile.displayName
                                    : 'My Account',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                authRepo.currentUser?.email ?? 'Pro Member',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: context.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout_rounded, size: 18, color: context.textMuted),
                          tooltip: 'Logout',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () async {
                            final confirmed = await AppConfirmationSheet.show(
                              context,
                              title: 'Log Out Account?',
                              message: 'Are you sure you want to sign out from this device?',
                              confirmLabel: 'Log Out',
                              isDestructive: true,
                            );
                            if (confirmed == true) {
                              await ref.read(authRepositoryProvider).signOut();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. MAIN CONTENT VIEWPORT (Right Area, No Top Navbar)
          Expanded(
            child: IndexedStack(
              index: selectedIndex.clamp(0, _desktopScreens.length - 1),
              children: _desktopScreens,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primaryAccent = isDark ? AppColors.primary : const Color(0xFF15803D);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryAccent.withValues(alpha: isDark ? 0.2 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primaryAccent.withValues(alpha: isDark ? 0.6 : 0.4)
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? primaryAccent
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : context.textSecondary,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
