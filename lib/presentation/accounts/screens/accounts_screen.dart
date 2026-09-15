import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/app_confirmation_sheet.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/donut_breakdown_chart.dart';
import '../../../core/widgets/spline_trend_chart.dart';
import '../../../domain/entities/account_balance.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/saving_goal.dart';
import '../../../domain/entities/transaction.dart';
import '../../categories/providers/category_providers.dart';
import '../../repository_providers.dart';
import '../../saving_goals/providers/saving_goal_providers.dart';
import '../../saving_goals/utils/saving_goal_ui_helpers.dart';
import '../../saving_goals/widgets/deposit_saving_goal_dialog.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/screens/add_transaction_sheet.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card_carousel.dart';
import 'add_account_sheet.dart';
import '../../shell/main_shell.dart';

class _RealAnalyticsData {
  final num totalAmount;
  final num prevAmount;
  final double growthPct;
  final num dailyAverage;
  final num peakAmount;
  final String peakPeriodLabel;
  final List<DonutSegment> donutSegments;
  final List<double> trendPoints;
  final List<String> trendLabels;
  final int highlightTrendIndex;
  final String highlightTrendLabel;
  final String currencySymbol;
  final String currencyCode;
  final int transactionCount;

  _RealAnalyticsData({
    required this.totalAmount,
    required this.prevAmount,
    required this.growthPct,
    required this.dailyAverage,
    required this.peakAmount,
    required this.peakPeriodLabel,
    required this.donutSegments,
    required this.trendPoints,
    required this.trendLabels,
    required this.highlightTrendIndex,
    required this.highlightTrendLabel,
    required this.currencySymbol,
    required this.currencyCode,
    required this.transactionCount,
  });
}

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  int _activeCardIndex = 0;
  int _selectedAnalyticsTab = 0; // 0: Overview, 1: Spending, 2: Income
  bool _showBalance = true;
  String _overviewTimeframe = 'This month';
  String _spendingTrendTimeframe = 'This month';
  String _incomeOverviewTimeframe = 'This month';
  String _incomeTrendTimeframe = 'This month';

  final List<String> _analyticsTabs = const ['Overview', 'Spending', 'Income'];

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(accountBalancesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final savingGoalsAsync = ref.watch(savingGoalsProvider);

    final balances = balancesAsync.asData?.value ?? [];
    final transactions = transactionsAsync.asData?.value ?? [];
    final categories = categoriesAsync.asData?.value ?? [];
    final savingGoals = savingGoalsAsync.asData?.value ?? [];

    final isAddAccountSelected = balances.isNotEmpty && _activeCardIndex >= balances.length;

    final expenseOverviewData = _computeRealAnalytics(
      transactions: transactions,
      categories: categories,
      balances: balances,
      timeframe: _overviewTimeframe,
      activeCardIndex: _activeCardIndex,
      transactionType: 'expense',
    );

    final expenseTrendData = _computeRealAnalytics(
      transactions: transactions,
      categories: categories,
      balances: balances,
      timeframe: _spendingTrendTimeframe,
      activeCardIndex: _activeCardIndex,
      transactionType: 'expense',
    );

    final incomeOverviewData = _computeRealAnalytics(
      transactions: transactions,
      categories: categories,
      balances: balances,
      timeframe: _incomeOverviewTimeframe,
      activeCardIndex: _activeCardIndex,
      transactionType: 'income',
    );

    final incomeTrendData = _computeRealAnalytics(
      transactions: transactions,
      categories: categories,
      balances: balances,
      timeframe: _incomeTrendTimeframe,
      activeCardIndex: _activeCardIndex,
      transactionType: 'income',
    );

    String? activeAccountId;
    String activeCurrencyCode = 'IDR';
    if (balances.isNotEmpty && _activeCardIndex < balances.length) {
      activeAccountId = balances[_activeCardIndex].accountId;
      activeCurrencyCode = balances[_activeCardIndex].currency;
    } else if (balances.isNotEmpty) {
      activeCurrencyCode = balances.first.currency;
    }

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
              ref.invalidate(categoriesProvider);
              ref.invalidate(savingGoalsProvider);
              await Future.wait([
                ref.read(accountBalancesProvider.future),
                ref.read(transactionsProvider.future),
                ref.read(categoriesProvider.future),
                ref.read(savingGoalsProvider.future),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                // 1. Header (Title & Standardized Add Button & Eye Toggle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accounts & Wallets',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        // Eye Visibility Toggle
                        GestureDetector(
                          onTap: () => setState(() => _showBalance = !_showBalance),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.cardBg,
                              border: Border.all(color: context.cardBorder),
                            ),
                            child: Icon(
                              _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => AddAccountSheet.show(context),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 18, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
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
                const SizedBox(height: 18),

                // 2. Swipable Horizontal Digital Card Carousel
                balancesAsync.when(
                  data: (balancesList) {
                    if (balancesList.isEmpty) {
                      return _buildEmptyAccountsHero();
                    }
                    return AccountCardCarousel(
                      balances: balancesList,
                      currentIndex: _activeCardIndex.clamp(0, balancesList.length),
                      showBalance: _showBalance,
                      onPageChanged: (idx) => setState(() => _activeCardIndex = idx),
                      onAddAccount: () => AddAccountSheet.show(context),
                      onToggleActive: (b) => _handleToggleAccountActive(context, ref, b),
                    );
                  },
                  loading: () => const _LoadingBlock(height: 195),
                  error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
                ),
                const SizedBox(height: 18),

                // If user slides to the "Add New Account" card, display the Add Account guide
                if (isAddAccountSelected) ...[
                  _buildAddAccountSlidePlaceholder(context),
                ] else ...[
                  // 3. Analytics Filter Pills (Overview | Spending | Income)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _analyticsTabs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedAnalyticsTab == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAnalyticsTab = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : context.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : context.cardBorder,
                              ),
                            ),
                            child: Text(
                              _analyticsTabs[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.black : context.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                // 4. Tab Contents
                // Tab 0: OVERVIEW (Net Cash Flow + Linked Goals + Spending Donut + Spending Trend)
                if (_selectedAnalyticsTab == 0) ...[
                  _buildNetCashFlowSummaryCard(
                    totalIncome: incomeOverviewData.totalAmount,
                    totalExpense: expenseOverviewData.totalAmount,
                    currencyCode: activeCurrencyCode,
                  ),
                  const SizedBox(height: 16),
                  _buildLinkedSavingGoalsCard(
                    goals: savingGoals,
                    activeAccountId: activeAccountId,
                    currencyCode: activeCurrencyCode,
                  ),
                  const SizedBox(height: 16),
                  _buildSpendingOverviewCard(expenseOverviewData),
                  const SizedBox(height: 16),
                  _buildSpendingTrendCard(expenseTrendData),
                ],

                // Tab 1: SPENDING (Spending Overview Donut + Spending Trend)
                if (_selectedAnalyticsTab == 1) ...[
                  _buildSpendingOverviewCard(expenseOverviewData),
                  const SizedBox(height: 16),
                  _buildSpendingTrendCard(expenseTrendData),
                ],

                // Tab 2: INCOME (Income Inflow Donut + Income Trend)
                if (_selectedAnalyticsTab == 2) ...[
                  _buildIncomeOverviewCard(incomeOverviewData),
                  const SizedBox(height: 16),
                  _buildIncomeTrendCard(incomeTrendData),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildEmptyAccountsHero() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
            'No accounts registered yet',
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => AddAccountSheet.show(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add First Account', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountSlidePlaceholder(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.15),
              border: Border.all(color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.4)),
            ),
            child: Icon(
              Icons.add_card_rounded,
              size: 28,
              color: context.accentIconColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Register a New Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new Bank, E-Wallet, or Cash account to start logging transactions, tracking spending velocity, and linking dedicated saving goals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => AddAccountSheet.show(context),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.black),
            label: const Text(
              'Create Account',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetCashFlowSummaryCard({
    required num totalIncome,
    required num totalExpense,
    required String currencyCode,
  }) {
    final netCashFlow = totalIncome - totalExpense;
    final isPositive = netCashFlow >= 0;

    final incomeStr = currencyCode == 'MYR'
        ? '+RM ${_formatNumber(totalIncome)}'
        : '+Rp ${_formatNumber(totalIncome)}';

    final expenseStr = currencyCode == 'MYR'
        ? '-RM ${_formatNumber(totalExpense)}'
        : '-Rp ${_formatNumber(totalExpense)}';

    final savingsRate = totalIncome > 0 ? ((netCashFlow / totalIncome) * 100).clamp(-100.0, 100.0) : 0.0;
    final expenseRatio = totalIncome > 0 ? (totalExpense / totalIncome).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Flow Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.green.withValues(alpha: 0.15) : AppColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPositive ? AppColors.green.withValues(alpha: 0.35) : AppColors.red.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                      size: 13,
                      color: isPositive ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPositive ? 'Net Surplus ${savingsRate.toStringAsFixed(0)}%' : 'Deficit ${savingsRate.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Net Balance Hero Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Balance',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: isPositive ? '+' : '-',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isPositive ? AppColors.green : AppColors.red,
                              ),
                            ),
                            TextSpan(
                              text: currencyCode == 'MYR'
                                  ? 'RM ${_formatNumber(netCashFlow.abs())}'
                                  : 'Rp ${_formatNumber(netCashFlow.abs())}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Cash Flow Ratio Bar
          if (totalIncome > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    Expanded(
                      flex: ((1.0 - expenseRatio) * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.green),
                    ),
                    if (expenseRatio > 0)
                      Expanded(
                        flex: (expenseRatio * 100).round().clamp(1, 100),
                        child: Container(color: AppColors.orange),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 2-Column Split for Inflow & Outflow (Full Width & No Truncation)
          Row(
            children: [
              // Inflow Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.isDark ? Colors.black26 : context.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 13, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Total Inflow',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          incomeStr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Outflow Box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.isDark ? Colors.black26 : context.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Total Outflow',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          expenseStr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
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

  Widget _buildLinkedSavingGoalsCard({
    required List<SavingGoal> goals,
    required String? activeAccountId,
    required String currencyCode,
  }) {
    final linkedGoals = goals.where((g) {
      if (activeAccountId == null) return false;
      return g.accountId == activeAccountId;
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.savings_outlined, size: 18, color: context.accentIconColor),
                  const SizedBox(width: 8),
                  Text(
                    'Linked Saving Goals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  if (linkedGoals.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: context.isDark ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${linkedGoals.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.accentLinkColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: () => ref.read(bottomNavIndexProvider.notifier).setIndex(4),
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
          const SizedBox(height: 12),
          if (linkedGoals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.black12 : context.inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.track_changes_outlined, size: 22, color: context.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No active saving goals funded by this account.',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: linkedGoals.take(3).map((goal) {
                final progress = goal.targetAmount > 0
                    ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                    : 0.0;
                final pct = (progress * 100).toStringAsFixed(0);

                final currentStr = goal.currency == 'MYR'
                    ? 'RM ${_formatNumber(goal.currentAmount)}'
                    : 'Rp ${_formatNumber(goal.currentAmount)}';
                final targetStr = goal.currency == 'MYR'
                    ? 'RM ${_formatNumber(goal.targetAmount)}'
                    : 'Rp ${_formatNumber(goal.targetAmount)}';

                final accentColor = SavingGoalUIHelper.parseColor(goal.color);
                final contrastAccent = SavingGoalUIHelper.getContrastColor(accentColor, context);
                final iconData = SavingGoalUIHelper.getIconData(goal.icon);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.isDark ? Colors.black26 : context.inputBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  iconData,
                                  size: 16,
                                  color: contrastAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                goal.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => DepositSavingGoalDialog.show(context, goal),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '+ Deposit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: context.cardBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$currentStr / $targetStr',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: contrastAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSpendingOverviewCard(_RealAnalyticsData data) {
    final hasExpenses = data.totalAmount > 0 && data.donutSegments.isNotEmpty;
    final formattedTotal = data.currencyCode == 'MYR'
        ? 'RM ${_formatNumber(data.totalAmount)}'
        : 'Rp ${_formatNumber(data.totalAmount)}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header (Title & Timeframe Selector)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              _buildTimeframeDropdown(
                value: _overviewTimeframe,
                onChanged: (val) => setState(() => _overviewTimeframe = val),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real Big Bold Total & Real Trend Metric
          Text(
            formattedTotal,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                data.growthPct >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: data.growthPct >= 0 ? AppColors.orange : AppColors.green,
              ),
              const SizedBox(width: 2),
              Text(
                '${data.growthPct.abs().toStringAsFixed(1)}% vs previous period',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.growthPct >= 0 ? AppColors.orange : AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Two-Column Split or Empty State
          if (!hasExpenses)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.black26 : context.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 38, color: context.textMuted),
                  const SizedBox(height: 10),
                  Text(
                    'No expenses recorded for this period',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => AddTransactionSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+ Record Expense',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Categories List with High-Contrast Hierarchy
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.donutSegments.take(4).map((seg) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Glowing Dot Indicator
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: seg.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: seg.color.withValues(alpha: 0.6),
                                    blurRadius: 5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          seg.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: seg.color.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          seg.percentageFormatted ?? '${seg.percentage.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: seg.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    seg.formattedAmount ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondary,
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

                const SizedBox(width: 8),

                // Right Real Donut Chart with Dynamic Center Badge
                Expanded(
                  flex: 4,
                  child: Center(
                    child: DonutBreakdownChart(
                      segments: data.donutSegments,
                      size: 132,
                      strokeWidth: 16,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendCard(_RealAnalyticsData data) {
    final dailyAvgFormatted = data.currencyCode == 'MYR'
        ? 'RM ${_formatNumber(data.dailyAverage)} / day'
        : 'Rp ${_formatNumber(data.dailyAverage)} / day';

    final peakFormatted = data.currencyCode == 'MYR'
        ? 'RM ${_formatNumber(data.peakAmount)}'
        : 'Rp ${_formatNumber(data.peakAmount)}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Velocity & Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              _buildTimeframeDropdown(
                value: _spendingTrendTimeframe,
                onChanged: (val) => setState(() => _spendingTrendTimeframe = val),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Distinct Analytical Trend Metrics (No duplicate total header)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg. Daily Spending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dailyAvgFormatted,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 34,
                width: 1,
                color: context.cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peak Period',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.peakAmount > 0 ? '$peakFormatted (${data.peakPeriodLabel})' : '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Real Spline Bezier Wave Chart
          SplineTrendChart(
            height: 120,
            lineColor: const Color(0xFF818CF8),
            points: data.trendPoints,
            highlightIndex: data.highlightTrendIndex,
            highlightLabel: data.highlightTrendLabel,
            labels: data.trendLabels,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeOverviewCard(_RealAnalyticsData data) {
    final hasIncome = data.totalAmount > 0 && data.donutSegments.isNotEmpty;
    final formattedTotal = data.currencyCode == 'MYR'
        ? 'RM ${_formatNumber(data.totalAmount)}'
        : 'Rp ${_formatNumber(data.totalAmount)}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header (Title & Timeframe Selector)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              _buildTimeframeDropdown(
                value: _incomeOverviewTimeframe,
                onChanged: (val) => setState(() => _incomeOverviewTimeframe = val),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real Big Bold Total & Real Growth Metric
          Text(
            formattedTotal,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                data.growthPct >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: data.growthPct >= 0 ? AppColors.green : AppColors.orange,
              ),
              const SizedBox(width: 2),
              Text(
                '${data.growthPct.abs().toStringAsFixed(1)}% vs previous period',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.growthPct >= 0 ? AppColors.green : AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Two-Column Split or Empty State
          if (!hasIncome)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.black26 : context.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 38, color: context.textMuted),
                  const SizedBox(height: 10),
                  Text(
                    'No income recorded for this period',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => AddTransactionSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+ Record Income',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Categories List with High-Contrast Hierarchy
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.donutSegments.take(4).map((seg) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Glowing Dot Indicator
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: seg.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: seg.color.withValues(alpha: 0.6),
                                    blurRadius: 5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          seg.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: seg.color.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          seg.percentageFormatted ?? '${seg.percentage.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: seg.color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    seg.formattedAmount ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.textSecondary,
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

                const SizedBox(width: 8),

                // Right Real Donut Chart with Dynamic Center Badge
                Expanded(
                  flex: 4,
                  child: Center(
                    child: DonutBreakdownChart(
                      segments: data.donutSegments,
                      size: 132,
                      strokeWidth: 16,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildIncomeTrendCard(_RealAnalyticsData data) {
    final dailyAvgFormatted = data.currencyCode == 'MYR'
        ? 'RM ${_formatNumber(data.dailyAverage)} / day'
        : 'Rp ${_formatNumber(data.dailyAverage)} / day';

    final peakFormatted = data.currencyCode == 'MYR'
        ? 'RM ${_formatNumber(data.peakAmount)}'
        : 'Rp ${_formatNumber(data.peakAmount)}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income Inflow Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              _buildTimeframeDropdown(
                value: _incomeTrendTimeframe,
                onChanged: (val) => setState(() => _incomeTrendTimeframe = val),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Distinct Metrics: Daily Average Inflow & Peak Inflow Day
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avg. Daily Inflow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dailyAvgFormatted,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 34,
                width: 1,
                color: context.cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peak Period',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.peakAmount > 0 ? '$peakFormatted (${data.peakPeriodLabel})' : '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Emerald Spline Bezier Wave Chart
          SplineTrendChart(
            height: 120,
            lineColor: const Color(0xFF10B981),
            points: data.trendPoints,
            highlightIndex: data.highlightTrendIndex,
            highlightLabel: data.highlightTrendLabel,
            labels: data.trendLabels,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeDropdown({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return AppFilterDropdown<String>(
      value: value,
      onChanged: onChanged,
      items: const [
        AppDropdownItem(value: 'This month', label: 'This month'),
        AppDropdownItem(value: 'Last 30 days', label: 'Last 30 days'),
        AppDropdownItem(value: 'This year', label: 'This year'),
      ],
    );
  }

  _RealAnalyticsData _computeRealAnalytics({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<AccountBalance> balances,
    required String timeframe,
    required int activeCardIndex,
    required String transactionType,
  }) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    DateTime prevStartDate;
    DateTime prevEndDate;
    List<String> trendLabels = [];
    int activeDays = 1;

    // Determine date ranges based on timeframe
    if (timeframe == 'Last 30 days') {
      endDate = now;
      startDate = now.subtract(const Duration(days: 30));
      prevEndDate = startDate;
      prevStartDate = startDate.subtract(const Duration(days: 30));
      activeDays = 30;

      trendLabels = ['-24d', '-18d', '-12d', '-6d', 'Today'];
    } else if (timeframe == 'This year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      prevStartDate = DateTime(now.year - 1, 1, 1);
      prevEndDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
      activeDays = (now.difference(DateTime(now.year, 1, 1)).inDays + 1).clamp(1, 365);

      trendLabels = ['Q1', 'Q2', 'Q3', 'Q4', 'Now'];
    } else {
      // 'This month' (Default)
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      prevStartDate = DateTime(now.year, now.month - 1, 1);
      prevEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      activeDays = now.day.clamp(1, 31);

      final monthName = _getMonthShort(now.month);
      final daysInMonth = endDate.day;
      trendLabels = [
        '1 $monthName',
        '${(daysInMonth * 0.25).round()} $monthName',
        '${(daysInMonth * 0.5).round()} $monthName',
        '${(daysInMonth * 0.75).round()} $monthName',
        '$daysInMonth $monthName',
      ];
    }

    // Active account context (if user selected a specific card in carousel)
    String? filterAccountId;
    String currency = 'IDR';
    if (balances.isNotEmpty && activeCardIndex < balances.length) {
      filterAccountId = balances[activeCardIndex].accountId;
      currency = balances[activeCardIndex].currency;
    } else if (balances.isNotEmpty) {
      currency = balances.first.currency;
    }

    final currencySymbol = currency == 'MYR' ? 'RM' : 'Rp';

    // Filter current period transactions
    final currentTransactions = transactions.where((t) {
      if (t.type != transactionType) return false;
      if (filterAccountId != null && t.accountId != filterAccountId) return false;
      return t.transactionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    final totalAmount = currentTransactions.fold<num>(0, (sum, t) => sum + t.amount);

    // Filter previous period transactions for real growth %
    final prevTransactions = transactions.where((t) {
      if (t.type != transactionType) return false;
      if (filterAccountId != null && t.accountId != filterAccountId) return false;
      return t.transactionDate.isAfter(prevStartDate.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(prevEndDate.add(const Duration(seconds: 1)));
    }).toList();

    final prevAmount = prevTransactions.fold<num>(0, (sum, t) => sum + t.amount);

    double growthPct = 0;
    if (prevAmount > 0) {
      growthPct = ((totalAmount - prevAmount) / prevAmount) * 100;
    } else if (totalAmount > 0) {
      growthPct = 100.0;
    }

    final dailyAverage = activeDays > 0 ? (totalAmount / activeDays) : 0;

    // Category map for category names
    final categoryMap = {for (final c in categories) c.id: c.name};

    // Group by category for Donut Chart
    final Map<String, double> categorySums = {};
    for (final t in currentTransactions) {
      String catName;
      final descLower = t.description?.toLowerCase() ?? '';
      if (transactionType == 'expense' &&
          (descLower.contains('deposit to saving goal') || descLower.contains('saving goal'))) {
        catName = 'Saving Goals';
      } else if (transactionType == 'income' &&
          (descLower.contains('withdrawal from saving goal') || descLower.contains('saving goal'))) {
        catName = 'Goal Withdrawals';
      } else if (t.categoryId != null && categoryMap.containsKey(t.categoryId)) {
        catName = categoryMap[t.categoryId]!;
      } else {
        catName = transactionType == 'income' ? 'General Income' : 'Uncategorized';
      }
      categorySums[catName] = (categorySums[catName] ?? 0) + t.amount.toDouble();
    }

    // Dedicated reserved signature colors
    const reservedSavingColor = Color(0xFFCCFF00); // Signature Neon Lime
    const reservedWithdrawalColor = Color(0xFF14B8A6); // Signature Teal

    // High-contrast, vibrant curated palettes (completely free of collision with reserved colors)
    const distinctExpensePalette = [
      Color(0xFFEC4899), // Hot Pink (e.g. Makan)
      Color(0xFF6366F1), // Indigo (e.g. Minum)
      Color(0xFFF59E0B), // Amber / Warm Yellow
      Color(0xFF06B6D4), // Electric Cyan
      Color(0xFFA855F7), // Purple
      Color(0xFF3B82F6), // Royal Blue
      Color(0xFFEF4444), // Coral Red
      Color(0xFFF97316), // Orange
    ];

    const distinctIncomePalette = [
      Color(0xFF10B981), // Emerald Green
      Color(0xFF3B82F6), // Royal Blue
      Color(0xFF8B5CF6), // Purple
      Color(0xFFF59E0B), // Amber
      Color(0xFF06B6D4), // Cyan
      Color(0xFFEC4899), // Pink
    ];

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Consolidate beyond top 4 into 'Others' if there are many categories
    final List<MapEntry<String, double>> displayCategories = [];
    if (sortedCategories.length <= 4) {
      displayCategories.addAll(sortedCategories);
    } else {
      displayCategories.addAll(sortedCategories.take(3));
      final otherSum = sortedCategories.skip(3).fold<double>(0, (sum, e) => sum + e.value);
      if (otherSum > 0) {
        displayCategories.add(MapEntry('Others', otherSum));
      }
    }

    final List<DonutSegment> donutSegments = [];
    int regularPaletteIdx = 0;
    for (int i = 0; i < displayCategories.length; i++) {
      final entry = displayCategories[i];
      final double pctVal = totalAmount > 0 ? (entry.value / totalAmount * 100) : 0;
      final String pctStr = pctVal >= 99.5 && pctVal <= 100.0
          ? '100%'
          : pctVal < 1.0 && pctVal > 0.0
              ? '<1%'
              : '${pctVal.toStringAsFixed(0)}%';

      final formattedAmount = currency == 'MYR'
          ? 'RM ${_formatNumber(entry.value)}'
          : 'Rp ${_formatNumber(entry.value)}';

      Color segColor;
      if (entry.key == 'Saving Goals') {
        segColor = reservedSavingColor;
      } else if (entry.key == 'Goal Withdrawals') {
        segColor = reservedWithdrawalColor;
      } else if (entry.key == 'Others') {
        segColor = const Color(0xFF64748B); // Dedicated Slate Gray for Others
      } else {
        final palette = transactionType == 'income' ? distinctIncomePalette : distinctExpensePalette;
        segColor = palette[regularPaletteIdx % palette.length];
        regularPaletteIdx++;
      }

      donutSegments.add(
        DonutSegment(
          label: entry.key,
          value: entry.value,
          color: segColor,
          percentage: pctVal,
          percentageFormatted: pctStr,
          formattedAmount: formattedAmount,
        ),
      );
    }

    // Calculate Real Trend Points (divide timeframe into 5 intervals)
    final totalDurationMs = endDate.difference(startDate).inMilliseconds;
    final intervalMs = (totalDurationMs / 5).clamp(1.0, double.infinity);

    final List<double> trendPoints = List.filled(5, 0.0);
    for (final t in currentTransactions) {
      final offsetMs = t.transactionDate.difference(startDate).inMilliseconds;
      int intervalIdx = (offsetMs / intervalMs).floor();
      if (intervalIdx < 0) intervalIdx = 0;
      if (intervalIdx > 4) intervalIdx = 4;
      trendPoints[intervalIdx] += t.amount.toDouble();
    }

    // Find peak interval
    int highlightIndex = 0;
    double maxVal = 0;
    for (int i = 0; i < trendPoints.length; i++) {
      if (trendPoints[i] >= maxVal) {
        maxVal = trendPoints[i];
        highlightIndex = i;
      }
    }

    final peakPeriodLabel = trendLabels.isNotEmpty && highlightIndex < trendLabels.length
        ? trendLabels[highlightIndex]
        : '';

    final highlightTrendLabel = currency == 'MYR'
        ? 'RM ${_formatNumber(maxVal)}'
        : 'Rp ${_formatNumber(maxVal)}';

    return _RealAnalyticsData(
      totalAmount: totalAmount,
      prevAmount: prevAmount,
      growthPct: growthPct,
      dailyAverage: dailyAverage,
      peakAmount: maxVal,
      peakPeriodLabel: peakPeriodLabel,
      donutSegments: donutSegments,
      trendPoints: trendPoints,
      trendLabels: trendLabels,
      highlightTrendIndex: highlightIndex,
      highlightTrendLabel: highlightTrendLabel,
      currencySymbol: currencySymbol,
      currencyCode: currency,
      transactionCount: currentTransactions.length,
    );
  }

  String _getMonthShort(int month) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return m[month];
    return '';
  }

  Future<void> _handleToggleAccountActive(BuildContext context, WidgetRef ref, AccountBalance balance) async {
    if (balance.isActive) {
      final confirm = await AppConfirmationSheet.show(
        context,
        title: 'Deactivate Account',
        message: 'Are you sure you want to deactivate "${balance.name}"? The card will remain visible with an inactive status.',
        confirmLabel: 'Deactivate Account',
        icon: Icons.lock_outline_rounded,
      );

      if (confirm == true) {
        final repo = ref.read(accountRepositoryProvider);
        await repo.deactivate(balance.accountId);
        ref.invalidate(accountsProvider);
        ref.invalidate(accountBalancesProvider);
      }
    } else {
      final confirm = await AppConfirmationSheet.show(
        context,
        title: 'Reactivate Account',
        message: 'Do you want to reactivate "${balance.name}"? It will return to active status.',
        confirmLabel: 'Reactivate Account',
        confirmColor: AppColors.green,
        icon: Icons.lock_open_rounded,
      );

      if (confirm == true) {
        final repo = ref.read(accountRepositoryProvider);
        await repo.activate(balance.accountId);
        ref.invalidate(accountsProvider);
        ref.invalidate(accountBalancesProvider);
      }
    }
  }

  static String _formatNumber(num val) {
    final s = val.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({this.height = 90});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
        ),
      ),
    );
  }
}
