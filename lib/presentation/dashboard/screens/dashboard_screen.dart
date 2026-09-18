import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../domain/entities/account_balance.dart';
import '../../../domain/entities/bill.dart';
import '../../../domain/entities/bill_payment.dart';
import '../../../domain/entities/transaction.dart';
import '../../accounts/providers/account_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bills/providers/bill_providers.dart';
import '../../bills/screens/add_bill_sheet.dart';
import '../../exchange_rates/screens/exchange_rate_screen.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../repository_providers.dart';
import '../../saving_goals/providers/saving_goal_providers.dart';
import '../../saving_goals/screens/add_saving_goal_sheet.dart';
import '../../settings/screens/settings_screen.dart';
import '../../shell/main_shell.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/screens/add_transaction_sheet.dart';
import '../../transfers/screens/add_transfer_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _activeHeroCurrency = 'IDR';
  String _overviewTimeframe = 'This month';
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(accountBalancesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final billsAsync = ref.watch(billsProvider);
    final paymentsAsync = ref.watch(currentMonthBillPaymentsProvider);
    final unreadNotificationCount = ref.watch(unreadNotificationsCountProvider);

    final balances = balancesAsync.asData?.value ?? [];
    final transactions = transactionsAsync.asData?.value ?? [];
    final bills = billsAsync.asData?.value ?? [];
    final payments = paymentsAsync.asData?.value ?? [];
    final accountMap = {for (final b in balances) b.accountId: b};

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
            backgroundColor: context.cardBg,
            onRefresh: () async {
              ref.invalidate(accountBalancesProvider);
              ref.invalidate(accountsProvider);
              ref.invalidate(transactionsProvider);
              ref.invalidate(billsProvider);
              ref.invalidate(currentMonthBillPaymentsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
              ref.invalidate(savingGoalsProvider);
              await Future.wait([
                ref.read(accountBalancesProvider.future),
                ref.read(transactionsProvider.future),
                ref.read(billsProvider.future),
                ref.read(savingGoalsProvider.future),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                // 1. Header (Avatar, Greeting & Notification)
                _buildHeader(unreadNotificationCount),
                const SizedBox(height: 20),

                // 2. Signature Electric Lime Hero Account Balance Card
                balancesAsync.when(
                  data: (balances) => _buildHeroBalance(balances, transactions, accountMap),
                  loading: () => const _LoadingHero(),
                  error: (e, _) => _buildHeroBalance([], transactions, accountMap),
                ),
                const SizedBox(height: 22),

                // 3. 4 Quick Action Buttons (Add, Transfer, Bills, Rates)
                _buildQuickActions(),
                const SizedBox(height: 24),

                // 4. 2x2 Bento Overview Grid (Income, Expenses, Savings, Bills)
                _buildBentoOverviewSection(transactions, balances, bills, payments, accountMap),
                const SizedBox(height: 24),

                // 5. Activity / Recent Transactions in Large Dark Card
                _buildRecentActivitySection(transactionsAsync, accountMap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int unpaidBillsCount) {
    final profile = ref.watch(userProfileProvider);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    final firstName = profile?.displayName.split(' ').first ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar + Greeting
        Row(
          children: [
            AppAvatar(
              avatarUrl: profile?.avatarUrl,
              initialLetter: profile?.initialLetter ?? 'U',
              size: 44,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isNotEmpty ? 'Hello, $firstName' : 'Hello,',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right Notification Action Button (Opens Notifications Screen)
        GestureDetector(
          onTap: () => NotificationsScreen.show(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.cardBg,
                  border: Border.all(color: context.cardBorder),
                  boxShadow: context.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: context.textPrimary,
                ),
              ),
              if (unpaidBillsCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: context.isDark ? AppColors.darkBackground : Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.red.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        unpaidBillsCount > 9 ? '9+' : '$unpaidBillsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBalance(
    List<AccountBalance> balances,
    List<Transaction> transactions,
    Map<String, AccountBalance> accountMap,
  ) {
    final activeBalances = balances.where((b) => b.isActive).toList();
    final idrBalances = activeBalances.where((b) => b.currency == 'IDR').toList();
    final myrBalances = activeBalances.where((b) => b.currency == 'MYR').toList();
    final totalIdr = idrBalances.fold<num>(0, (sum, b) => sum + b.balance);
    final totalMyr = myrBalances.fold<num>(0, (sum, b) => sum + b.balance);

    final isIdr = _activeHeroCurrency == 'IDR';
    final activeBalance = isIdr ? totalIdr : totalMyr;
    final activeSymbol = isIdr ? 'Rp' : 'RM';
    final activeAccountsCount = isIdr ? idrBalances.length : myrBalances.length;

    // Calculate Credit (Income) & Debit (Expense) for active currency
    final creditTotal = transactions
        .where((t) => t.type == 'income' && accountMap[t.accountId]?.currency == _activeHeroCurrency)
        .fold<num>(0, (sum, t) => sum + t.amount);
    final debitTotal = transactions
        .where((t) => t.type == 'expense' && accountMap[t.accountId]?.currency == _activeHeroCurrency)
        .fold<num>(0, (sum, t) => sum + t.amount);

    final formattedActiveBalance = isIdr ? _formatRupiah(activeBalance) : _formatMyr(activeBalance);
    final formattedCredit = isIdr ? 'Rp ${_formatRupiah(creditTotal)}' : 'RM ${_formatMyr(creditTotal)}';
    final formattedDebit = isIdr ? 'Rp ${_formatRupiah(debitTotal)}' : 'RM ${_formatMyr(debitTotal)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.limeCardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row inside Lime Card (Label, Multi-Currency Tabs & Eye Toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Account balance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2405),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($activeAccountsCount acc)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A5610),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Currency Tab Switcher
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeroCurrencyTab(
                          label: 'IDR',
                          isActive: isIdr,
                          onTap: () => setState(() => _activeHeroCurrency = 'IDR'),
                        ),
                        _HeroCurrencyTab(
                          label: 'MYR',
                          isActive: !isIdr,
                          onTap: () => setState(() => _activeHeroCurrency = 'MYR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Eye Toggle
                  GestureDetector(
                    onTap: () => setState(() => _showBalance = !_showBalance),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Bold Balance Text
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$activeSymbol ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2405),
                  ),
                ),
                Text(
                  _showBalance ? formattedActiveBalance : '\u2022\u2022\u2022\u2022\u2022\u2022',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Color(0xFF0E0E10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Nested White Sub-Pills (Credit / Debit)
          Row(
            children: [
              // Credit (Income) Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Credit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _showBalance ? formattedCredit : '\u2022\u2022\u2022',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Debit (Expense) Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF453A),
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Debit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _showBalance ? formattedDebit : '\u2022\u2022\u2022',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionButton(
          icon: Icons.add_rounded,
          label: 'Add',
          isHighlighted: false,
          onTap: () => AddTransactionSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Transfer',
          isHighlighted: true,
          onTap: () => AddTransferSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.savings_rounded,
          label: 'Goals',
          isHighlighted: false,
          onTap: () => AddSavingGoalSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Bills',
          isHighlighted: false,
          onTap: () => AddBillSheet.show(context),
        ),
        _QuickActionButton(
          icon: Icons.currency_exchange_rounded,
          label: 'Rates',
          isHighlighted: false,
          onTap: () => ExchangeRateScreen.show(context),
        ),
      ],
    );
  }

  Widget _buildBentoOverviewSection(
    List<Transaction> transactions,
    List<AccountBalance> balances,
    List<Bill> bills,
    List<BillPayment> payments,
    Map<String, AccountBalance> accountMap,
  ) {
    // Calculate timeframe boundaries
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    DateTime prevStartDate;
    DateTime prevEndDate;

    if (_overviewTimeframe == 'Last 30 days') {
      endDate = now;
      startDate = now.subtract(const Duration(days: 30));
      prevEndDate = startDate;
      prevStartDate = startDate.subtract(const Duration(days: 30));
    } else if (_overviewTimeframe == 'This year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      prevStartDate = DateTime(now.year - 1, 1, 1);
      prevEndDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
    } else {
      // 'This month'
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      prevStartDate = DateTime(now.year, now.month - 1, 1);
      prevEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);
    }

    final isIdr = _activeHeroCurrency == 'IDR';

    // Current period transactions
    final currentPeriodTx = transactions.where((t) {
      final acc = accountMap[t.accountId];
      if (acc?.currency != _activeHeroCurrency) return false;
      return t.transactionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    // Previous period transactions
    final prevPeriodTx = transactions.where((t) {
      final acc = accountMap[t.accountId];
      if (acc?.currency != _activeHeroCurrency) return false;
      return t.transactionDate.isAfter(prevStartDate.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(prevEndDate.add(const Duration(seconds: 1)));
    }).toList();

    final currentIncome = currentPeriodTx
        .where((t) => t.type == 'income')
        .fold<num>(0, (sum, t) => sum + t.amount);
    final prevIncome = prevPeriodTx
        .where((t) => t.type == 'income')
        .fold<num>(0, (sum, t) => sum + t.amount);

    final currentExpense = currentPeriodTx
        .where((t) => t.type == 'expense')
        .fold<num>(0, (sum, t) => sum + t.amount);
    final prevExpense = prevPeriodTx
        .where((t) => t.type == 'expense')
        .fold<num>(0, (sum, t) => sum + t.amount);

    final double incomeGrowth = prevIncome > 0
        ? ((currentIncome - prevIncome) / prevIncome) * 100
        : (currentIncome > 0 ? 100.0 : 0.0);
    final double expenseGrowth = prevExpense > 0
        ? ((currentExpense - prevExpense) / prevExpense) * 100
        : (currentExpense > 0 ? 100.0 : 0.0);

    final netSavings = currentIncome - currentExpense;

    // Active bills logic
    final paidBillIds = payments
        .where((p) => p.status == 'paid')
        .map((p) => p.billId)
        .toSet();

    final allUnpaidBills = bills.where((b) => b.isActive && !paidBillIds.contains(b.id)).toList();
    final currencyBills = bills.where((b) => b.isActive && b.currency == _activeHeroCurrency).toList();
    final unpaidBills = currencyBills.where((b) => !paidBillIds.contains(b.id)).toList();
    final totalUnpaidBillsAmount = unpaidBills.fold<num>(0, (sum, b) => sum + b.amount);

    String formattedBills;
    String billsTrendText;
    bool? billsPositiveTrend;

    if (unpaidBills.isNotEmpty) {
      formattedBills = isIdr
          ? 'Rp ${_formatRupiah(totalUnpaidBillsAmount)}'
          : 'RM ${_formatMyr(totalUnpaidBillsAmount)}';
      billsTrendText = '${unpaidBills.length} unpaid';
      billsPositiveTrend = false;
    } else if (allUnpaidBills.isNotEmpty) {
      final otherCurrency = allUnpaidBills.first.currency;
      final otherTotal = allUnpaidBills
          .where((b) => b.currency == otherCurrency)
          .fold<num>(0, (sum, b) => sum + b.amount);
      formattedBills = otherCurrency == 'IDR'
          ? 'Rp ${_formatRupiah(otherTotal)}'
          : 'RM ${_formatMyr(otherTotal)}';
      billsTrendText = '${allUnpaidBills.length} unpaid ($otherCurrency)';
      billsPositiveTrend = false;
    } else {
      formattedBills = isIdr ? 'Rp 0' : 'RM 0';
      billsTrendText = 'All paid';
      billsPositiveTrend = true;
    }

    final formattedIncome = isIdr ? 'Rp ${_formatRupiah(currentIncome)}' : 'RM ${_formatMyr(currentIncome)}';
    final formattedExpense = isIdr ? 'Rp ${_formatRupiah(currentExpense)}' : 'RM ${_formatMyr(currentExpense)}';
    final formattedSavings = isIdr
        ? (netSavings >= 0 ? 'Rp ${_formatRupiah(netSavings)}' : '-Rp ${_formatRupiah(netSavings.abs())}')
        : (netSavings >= 0 ? 'RM ${_formatMyr(netSavings)}' : '-RM ${_formatMyr(netSavings.abs())}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Title & Timeframe Filter)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            AppFilterDropdown<String>(
              value: _overviewTimeframe,
              onChanged: (val) => setState(() => _overviewTimeframe = val),
              items: const [
                AppDropdownItem(value: 'This month', label: 'This month'),
                AppDropdownItem(value: 'Last 30 days', label: 'Last 30 days'),
                AppDropdownItem(value: 'This year', label: 'This year'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Bento Grid
        Row(
          children: [
            Expanded(
              child: _BentoMetricCard(
                title: 'Income',
                amount: formattedIncome,
                icon: Icons.arrow_downward_rounded,
                accentColor: const Color(0xFF22C55E),
                trendText: '${incomeGrowth >= 0 ? '+' : ''}${incomeGrowth.abs().toStringAsFixed(1)}%',
                isPositiveTrend: incomeGrowth >= 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoMetricCard(
                title: 'Expenses',
                amount: formattedExpense,
                icon: Icons.receipt_long_rounded,
                accentColor: const Color(0xFFFF453A),
                trendText: '${expenseGrowth >= 0 ? '+' : ''}${expenseGrowth.abs().toStringAsFixed(1)}%',
                isPositiveTrend: expenseGrowth <= 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BentoMetricCard(
                title: 'Savings',
                amount: formattedSavings,
                icon: Icons.savings_rounded,
                accentColor: const Color(0xFF14B8A6),
                trendText: netSavings >= 0 ? 'Surplus' : 'Deficit',
                isPositiveTrend: netSavings >= 0,
                onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoMetricCard(
                title: 'Bills Due',
                amount: formattedBills,
                icon: Icons.calendar_month_rounded,
                accentColor: const Color(0xFFF59E0B),
                trendText: billsTrendText,
                isPositiveTrend: billsPositiveTrend,
                onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
    AsyncValue<List<Transaction>> transactionsAsync,
    Map<String, AccountBalance> accountMap,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.cardBorder),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Card (Title & View all Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_outlined, size: 36, color: context.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No activity recorded yet.',
                          style: TextStyle(color: context.textSecondary, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () => AddTransactionSheet.show(context),
                          child: Text(
                            'Record Transaction Now',
                            style: TextStyle(color: context.accentLinkColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: transactions
                    .take(5)
                    .map((t) {
                      final acc = accountMap[t.accountId];
                      final isMyr = acc?.currency == 'MYR';
                      final formattedVal = isMyr
                          ? 'RM ${_formatNumber(t.amount)}'
                          : 'Rp ${_formatNumber(t.amount)}';

                      return _ActivityItem(
                        title: t.description?.isNotEmpty == true ? t.description! : (t.type == 'expense' ? 'Expense' : 'Income'),
                        subtitle: '${acc != null ? '${acc.name} \u00b7 ' : ''}${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}',
                        amount: '${t.type == 'expense' ? '-' : '+'}$formattedVal',
                        isNegative: t.type == 'expense',
                      );
                    })
                    .toList(),
              );
            },
            loading: () => const _LoadingBlock(),
            error: (e, _) {
              final errStr = e.toString();
              if (errStr.contains('JWT expired') || errStr.contains('PGRST303')) {
                ref.read(authRepositoryProvider).refreshSessionIfNeeded();
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Session expired. Refreshing...',
                    style: TextStyle(color: AppColors.orange, fontSize: 12),
                  ),
                );
              }
              return Text('$e', style: const TextStyle(color: AppColors.red, fontSize: 12));
            },
          ),
        ],
      ),
    );
  }

  static String _formatNumber(num value) {
    if (value % 1 == 0) {
      final s = value.abs().toStringAsFixed(0);
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
        buffer.write(s[i]);
      }
      return buffer.toString();
    }
    final parts = value.abs().toStringAsFixed(2).split('.');
    final s = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '${buffer.toString()},${parts[1]}';
  }

  String _formatRupiah(num value) => _formatNumber(value);

  String _formatMyr(num value) => _formatNumber(value);
}

class _BentoMetricCard extends StatelessWidget {
  const _BentoMetricCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accentColor,
    this.trendText,
    this.isPositiveTrend,
    this.onTap,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color accentColor;
  final String? trendText;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorder),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: accentColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                if (trendText != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isPositiveTrend != null)
                        Icon(
                          isPositiveTrend! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 12,
                          color: isPositiveTrend! ? AppColors.green : AppColors.orange,
                        ),
                      if (isPositiveTrend != null) const SizedBox(width: 2),
                      Text(
                        trendText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPositiveTrend == null
                              ? context.textSecondary
                              : (isPositiveTrend! ? AppColors.green : AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCurrencyTab extends StatelessWidget {
  const _HeroCurrencyTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isActive ? AppColors.primary : const Color(0xFF2A3008),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isHighlighted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? AppColors.primary : context.cardBg,
              border: Border.all(
                color: isHighlighted
                    ? (context.isDark ? AppColors.primaryLight : const Color(0xFF15803D))
                    : context.cardBorder,
                width: 1.2,
              ),
              boxShadow: [
                if (isHighlighted)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  )
                else if (!context.isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: isHighlighted ? Colors.black : context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isNegative,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isNegative ? AppColors.red : (context.isDark ? AppColors.green : const Color(0xFF059669))).withValues(alpha: 0.15),
              border: Border.all(
                color: (isNegative ? AppColors.red : (context.isDark ? AppColors.green : const Color(0xFF059669))).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isNegative ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
              size: 18,
              color: isNegative ? AppColors.red : (context.isDark ? AppColors.green : const Color(0xFF059669)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isNegative ? AppColors.red : context.incomeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHero extends StatelessWidget {
  const _LoadingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.limeCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
        ),
      ),
    );
  }
}
