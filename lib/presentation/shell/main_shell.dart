import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../accounts/screens/accounts_screen.dart';
import '../bills/providers/bill_providers.dart';
import '../bills/screens/bills_screen.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../saving_goals/screens/saving_goals_screen.dart';
import '../transactions/screens/transactions_screen.dart';

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(
  BottomNavIndexNotifier.new,
);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    BillsScreen(),
    SavingGoalsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBottomPos = bottomInset > 0 ? bottomInset + 8 : 20.0;

    final bills = ref.watch(billsProvider).asData?.value ?? [];
    final payments = ref.watch(currentMonthBillPaymentsProvider).asData?.value ?? [];
    final activeBills = bills.where((b) => b.isActive).toList();
    final paidBillIds = payments.where((p) => p.status == 'paid').map((p) => p.billId).toSet();
    final unpaidBillsCount = activeBills.where((b) => !paidBillIds.contains(b.id)).length;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Screens Stack (Full Screen)
          IndexedStack(index: index, children: _screens),

          // 2. Bottom Fading Gradient Overlay (Translucent black fade)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150 + bottomInset,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0E0E10).withValues(alpha: 0.35),
                      const Color(0xFF0E0E10).withValues(alpha: 0.8),
                      const Color(0xFF0E0E10).withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Glassmorphism Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: navBottomPos,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181D).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        active: index == 0,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(0),
                      ),
                      _NavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Transactions',
                        active: index == 1,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(1),
                      ),
                      _NavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Accounts',
                        active: index == 2,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(2),
                      ),
                      _NavItem(
                        icon: Icons.notifications_active_rounded,
                        label: 'Bills',
                        active: index == 3,
                        badgeCount: unpaidBillsCount,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(3),
                      ),
                      _NavItem(
                        icon: Icons.savings_rounded,
                        label: 'Goals',
                        active: index == 4,
                        onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(4),
                      ),
                    ],
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: active ? 48 : 40,
            height: active ? 44 : 40,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: active ? Colors.black : AppColors.darkTextSecondary,
              ),
            ),
          ),
          if (badgeCount > 0 && !active)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red,
                  border: Border.all(color: const Color(0xFF18181D), width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
