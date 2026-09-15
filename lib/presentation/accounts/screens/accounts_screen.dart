import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/donut_breakdown_chart.dart';
import '../../../core/widgets/spline_trend_chart.dart';
import '../../../domain/entities/account_balance.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/transaction.dart';
import '../../categories/providers/category_providers.dart';
import '../../repository_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/screens/add_transaction_sheet.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card_carousel.dart';
import 'add_account_sheet.dart';

class _RealAnalyticsData {
  final num totalSpending;
  final num prevSpending;
  final double growthPct;
  final List<DonutSegment> donutSegments;
  final List<double> trendPoints;
  final List<String> trendLabels;
  final int highlightTrendIndex;
  final String highlightTrendLabel;
  final String currencySymbol;
  final String currencyCode;

  _RealAnalyticsData({
    required this.totalSpending,
    required this.prevSpending,
    required this.growthPct,
    required this.donutSegments,
    required this.trendPoints,
    required this.trendLabels,
    required this.highlightTrendIndex,
    required this.highlightTrendLabel,
    required this.currencySymbol,
    required this.currencyCode,
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
  String _trendTimeframe = 'This month';

  final List<String> _analyticsTabs = const ['Overview', 'Spending', 'Income'];

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(accountBalancesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final balances = balancesAsync.asData?.value ?? [];
    final transactions = transactionsAsync.asData?.value ?? [];
    final categories = categoriesAsync.asData?.value ?? [];

    final overviewData = _computeRealAnalytics(
      transactions: transactions,
      categories: categories,
      balances: balances,
      timeframe: _overviewTimeframe,
      activeCardIndex: _activeCardIndex,
    );

    final trendData = _computeRealAnalytics(
      transactions: transactions,
      categories: categories,
      balances: balances,
      timeframe: _trendTimeframe,
      activeCardIndex: _activeCardIndex,
    );

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              // 1. Header (Title & Standardized Add Button & Eye Toggle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accounts & Wallets',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.darkTextPrimary,
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
                            color: AppColors.darkCardBg,
                            border: Border.all(color: AppColors.darkCardBorder),
                          ),
                          child: Icon(
                            _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppColors.darkTextSecondary,
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
                    onDeactivate: (b) => _confirmDeactivate(context, ref, b),
                  );
                },
                loading: () => const _LoadingBlock(height: 195),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
              ),
              const SizedBox(height: 18),

              // 3. Analytics Filter Pills (Overview | Spending | Income | Accounts)
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
                          color: isSelected ? AppColors.primary : AppColors.darkCardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.darkCardBorder,
                          ),
                        ),
                        child: Text(
                          _analyticsTabs[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 4. Real Spending Overview Card with Real Donut Breakdown
              if (_selectedAnalyticsTab == 0 || _selectedAnalyticsTab == 1) ...[
                _buildSpendingOverviewCard(overviewData),
                const SizedBox(height: 16),
              ],

              // 5. Real Spending / Cash Flow Trend Wave Card
              if (_selectedAnalyticsTab == 0 || _selectedAnalyticsTab == 1 || _selectedAnalyticsTab == 2) ...[
                _buildSpendingTrendCard(trendData),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAccountsHero() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.darkTextMuted),
          const SizedBox(height: 12),
          const Text(
            'No accounts registered yet',
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
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

  Widget _buildSpendingOverviewCard(_RealAnalyticsData data) {
    final hasExpenses = data.totalSpending > 0 && data.donutSegments.isNotEmpty;
    final formattedTotal = data.currencyCode == 'MYR'
        ? 'RM ${data.totalSpending % 1 == 0 ? data.totalSpending.toStringAsFixed(0) : data.totalSpending.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(data.totalSpending)}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header (Title & Timeframe Selector)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
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
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.darkTextPrimary,
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
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, size: 38, color: AppColors.darkTextMuted),
                  const SizedBox(height: 10),
                  const Text(
                    'No expenses recorded for this period',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
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
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkTextPrimary,
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.darkTextSecondary,
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
    final formattedTotal = data.currencyCode == 'MYR'
        ? 'RM ${data.totalSpending % 1 == 0 ? data.totalSpending.toStringAsFixed(0) : data.totalSpending.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(data.totalSpending)}';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              _buildTimeframeDropdown(
                value: _trendTimeframe,
                onChanged: (val) => setState(() => _trendTimeframe = val),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real Value & Metric
          Text(
            formattedTotal,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.darkTextPrimary,
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
  }) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    DateTime prevStartDate;
    DateTime prevEndDate;
    List<String> trendLabels = [];

    // Determine date ranges based on timeframe
    if (timeframe == 'Last 30 days') {
      endDate = now;
      startDate = now.subtract(const Duration(days: 30));
      prevEndDate = startDate;
      prevStartDate = startDate.subtract(const Duration(days: 30));

      trendLabels = ['-24d', '-18d', '-12d', '-6d', 'Today'];
    } else if (timeframe == 'This year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      prevStartDate = DateTime(now.year - 1, 1, 1);
      prevEndDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);

      trendLabels = ['Q1', 'Q2', 'Q3', 'Q4', 'Now'];
    } else {
      // 'This month' (Default)
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      prevStartDate = DateTime(now.year, now.month - 1, 1);
      prevEndDate = DateTime(now.year, now.month, 0, 23, 59, 59);

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

    // Filter current period expenses
    final currentExpenses = transactions.where((t) {
      if (t.type != 'expense') return false;
      if (filterAccountId != null && t.accountId != filterAccountId) return false;
      return t.transactionDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    final totalSpending = currentExpenses.fold<num>(0, (sum, t) => sum + t.amount);

    // Filter previous period expenses for real growth %
    final prevExpenses = transactions.where((t) {
      if (t.type != 'expense') return false;
      if (filterAccountId != null && t.accountId != filterAccountId) return false;
      return t.transactionDate.isAfter(prevStartDate.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(prevEndDate.add(const Duration(seconds: 1)));
    }).toList();

    final prevSpending = prevExpenses.fold<num>(0, (sum, t) => sum + t.amount);

    double growthPct = 0;
    if (prevSpending > 0) {
      growthPct = ((totalSpending - prevSpending) / prevSpending) * 100;
    } else if (totalSpending > 0) {
      growthPct = 100.0;
    }

    // Category map for category names
    final categoryMap = {for (final c in categories) c.id: c.name};

    // Group by category for Donut Chart
    final Map<String, double> categorySums = {};
    for (final t in currentExpenses) {
      final catName = (t.categoryId != null ? categoryMap[t.categoryId] : null) ?? 'Uncategorized';
      categorySums[catName] = (categorySums[catName] ?? 0) + t.amount.toDouble();
    }

    const segmentColors = [
      Color(0xFFEC4899), // Pink
      Color(0xFF6366F1), // Indigo/Blue
      Color(0xFF84CC16), // Lime Green
      Color(0xFFF59E0B), // Amber
      Color(0xFF06B6D4), // Cyan
      Color(0xFFA855F7), // Purple
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
    for (int i = 0; i < displayCategories.length; i++) {
      final entry = displayCategories[i];
      final double pctVal = totalSpending > 0 ? (entry.value / totalSpending * 100) : 0;
      final String pctStr = pctVal >= 99.5 && pctVal <= 100.0
          ? '100%'
          : pctVal < 1.0 && pctVal > 0.0
              ? '<1%'
              : '${pctVal.toStringAsFixed(0)}%';

      final formattedAmount = currency == 'MYR'
          ? 'RM ${entry.value % 1 == 0 ? entry.value.toStringAsFixed(0) : entry.value.toStringAsFixed(2)}'
          : 'Rp ${_formatNumber(entry.value)}';

      donutSegments.add(
        DonutSegment(
          label: entry.key,
          value: entry.value,
          color: segmentColors[i % segmentColors.length],
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
    for (final t in currentExpenses) {
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

    final highlightTrendLabel = currency == 'MYR'
        ? 'RM ${maxVal % 1 == 0 ? maxVal.toStringAsFixed(0) : maxVal.toStringAsFixed(2)}'
        : 'Rp ${_formatNumber(maxVal)}';

    return _RealAnalyticsData(
      totalSpending: totalSpending,
      prevSpending: prevSpending,
      growthPct: growthPct,
      donutSegments: donutSegments,
      trendPoints: trendPoints,
      trendLabels: trendLabels,
      highlightTrendIndex: highlightIndex,
      highlightTrendLabel: highlightTrendLabel,
      currencySymbol: currencySymbol,
      currencyCode: currency,
    );
  }

  String _getMonthShort(int month) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return m[month];
    return '';
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref, AccountBalance balance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Deactivate Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to deactivate "${balance.name}"? It will no longer appear in your active accounts.',
          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(accountRepositoryProvider);
      await repo.deactivate(balance.accountId);
      ref.invalidate(accountsProvider);
      ref.invalidate(accountBalancesProvider);
    }
  }

  static String _formatNumber(num val) {
    final s = val.toStringAsFixed(0);
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
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
    );
  }
}
