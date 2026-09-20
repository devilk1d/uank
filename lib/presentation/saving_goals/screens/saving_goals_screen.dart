import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/saving_goal.dart';
import '../../accounts/providers/account_providers.dart';
import '../providers/saving_goal_providers.dart';
import '../utils/saving_goal_ui_helpers.dart';
import '../widgets/deposit_saving_goal_dialog.dart';
import 'add_saving_goal_sheet.dart';

class SavingGoalsScreen extends ConsumerStatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  ConsumerState<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends ConsumerState<SavingGoalsScreen> {
  int _selectedTabIndex = 0; // 0 = In Progress, 1 = Completed
  String _selectedCurrencyFilter = 'ALL'; // ALL, IDR, MYR

  Color _parseHexColor(String hex) => SavingGoalUIHelper.parseColor(hex);

  IconData _getIconData(String iconKey) => SavingGoalUIHelper.getIconData(iconKey);

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(savingGoalsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.asData?.value ?? [];
    final accountsMap = {for (final a in accounts) a.id: a};

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: RefreshIndicator(
            color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
            backgroundColor: context.cardBg,
            onRefresh: () async {
              ref.invalidate(savingGoalsProvider);
              ref.invalidate(accountsProvider);
              await ref.read(savingGoalsProvider.future);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 28 : 20,
                    isDesktop ? 24 : 16,
                    isDesktop ? 28 : 20,
                    isDesktop ? 48 : 110,
                  ),
                  children: [
                    // Header (Title & Add Goal CTA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saving Goals',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: context.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => AddSavingGoalSheet.show(context),
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
                    const SizedBox(height: 18),

                    goalsAsync.when(
                      data: (goals) {
                        // Filter goals by currency if selected
                        final currencyFiltered = _selectedCurrencyFilter == 'ALL'
                            ? goals
                            : goals.where((g) => g.currency == _selectedCurrencyFilter).toList();

                        final inProgressGoals = currencyFiltered.where((g) => !g.isCompleted && g.currentAmount < g.targetAmount).toList();
                        final completedGoals = currencyFiltered.where((g) => g.isCompleted || g.currentAmount >= g.targetAmount).toList();

                        final activeList = _selectedTabIndex == 0 ? inProgressGoals : completedGoals;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Overall Summary Banner
                            _buildSummaryBanner(goals),
                            const SizedBox(height: 20),

                            // 2. Tab Switcher & Currency Filter Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // In Progress / Completed Tabs
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildTabButton('In Progress (${inProgressGoals.length})', 0),
                                      _buildTabButton('Completed (${completedGoals.length})', 1),
                                    ],
                                  ),
                                ),

                                // Currency Filter
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: context.cardBorder),
                                  ),
                                  child: Row(
                                    children: ['ALL', 'IDR', 'MYR'].map((cur) {
                                      final isSelected = _selectedCurrencyFilter == cur;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedCurrencyFilter = cur),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (context.isDark ? AppColors.primary.withValues(alpha: 0.18) : const Color(0xFF15803D).withValues(alpha: 0.1))
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            cur,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? (context.isDark ? AppColors.primary : const Color(0xFF15803D))
                                                  : context.textSecondary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 3. Goals List / Empty State
                            if (activeList.isEmpty)
                              _buildEmptyState()
                            else if (isDesktop) ...[
                              // 2-Columns Grid on Desktop
                              LayoutBuilder(
                                builder: (context, gridConstraints) {
                                  final cardWidth = (gridConstraints.maxWidth - 16) / 2;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: activeList.map((goal) {
                                      return SizedBox(
                                        width: cardWidth,
                                        child: _buildGoalCard(goal, accountsMap[goal.accountId]?.name),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ] else
                              ...activeList.map((goal) => _buildGoalCard(goal, accountsMap[goal.accountId]?.name)),
                          ],
                        );
                      },
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.red),
                              const SizedBox(height: 8),
                              Text('Failed to load goals: $e', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                              TextButton(
                                onPressed: () => ref.invalidate(savingGoalsProvider),
                                child: Text('Retry', style: TextStyle(color: context.accentLinkColor)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildSummaryBanner(List<SavingGoal> goals) {
    final idrGoals = goals.where((g) => g.currency == 'IDR').toList();
    final myrGoals = goals.where((g) => g.currency == 'MYR').toList();

    final idrSaved = idrGoals.fold<num>(0, (sum, g) => sum + g.currentAmount);
    final idrTarget = idrGoals.fold<num>(0, (sum, g) => sum + g.targetAmount);

    final myrSaved = myrGoals.fold<num>(0, (sum, g) => sum + g.currentAmount);
    final myrTarget = myrGoals.fold<num>(0, (sum, g) => sum + g.targetAmount);

    final completedCount = goals.where((g) => g.isCompleted || g.currentAmount >= g.targetAmount).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: context.accentIconColor),
                  const SizedBox(width: 6),
                  Text(
                    'Overall Savings Progress',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$completedCount/${goals.length} Achieved',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total IDR Progress
          if (idrGoals.isNotEmpty) ...[
            _buildCurrencySummaryRow(
              currency: 'IDR',
              saved: idrSaved,
              target: idrTarget,
              accentColor: context.isDark ? AppColors.primary : const Color(0xFF15803D),
            ),
            if (myrGoals.isNotEmpty) const SizedBox(height: 12),
          ],

          // Total MYR Progress
          if (myrGoals.isNotEmpty)
            _buildCurrencySummaryRow(
              currency: 'MYR',
              saved: myrSaved,
              target: myrTarget,
              accentColor: AppColors.teal,
            ),

          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Set your first saving goal to visualize your financial milestones.',
                style: TextStyle(color: context.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencySummaryRow({
    required String currency,
    required num saved,
    required num target,
    required Color accentColor,
  }) {
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final isIdr = currency == 'IDR';
    final symbol = isIdr ? 'Rp' : 'RM';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$symbol ${CurrencyInputFormatter.format(saved)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            Text(
              'of $symbol ${CurrencyInputFormatter.format(target)} (${(progress * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: context.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(SavingGoal goal, [String? accountName]) {
    final accentColor = _parseHexColor(goal.color);
    final contrastAccent = SavingGoalUIHelper.getContrastColor(accentColor, context);
    final iconData = _getIconData(goal.icon);
    final isIdr = goal.currency == 'IDR';
    final symbol = isIdr ? 'Rp' : 'RM';

    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    final isCompleted = goal.isCompleted || goal.currentAmount >= goal.targetAmount;

    // Format deadline
    String? deadlineText;
    if (goal.targetDate != null && goal.targetDate!.isNotEmpty) {
      final date = DateTime.tryParse(goal.targetDate!);
      if (date != null) {
        final now = DateTime.now();
        final diffDays = date.difference(now).inDays;
        if (diffDays < 0) {
          deadlineText = 'Deadline passed';
        } else if (diffDays == 0) {
          deadlineText = 'Due today!';
        } else {
          deadlineText = '$diffDays days left';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted ? AppColors.teal.withValues(alpha: 0.5) : accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: context.isDark ? 0.08 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Title + Status / Edit
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Icon(iconData, size: 22, color: contrastAccent),
              ),
              const SizedBox(width: 12),

              // Title & Deadline / Currency / Account
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goal.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: context.inputBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            goal.currency,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (deadlineText != null) ...[
                          Icon(Icons.calendar_today_rounded, size: 11, color: isCompleted ? AppColors.teal : context.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCompleted ? AppColors.teal : context.textSecondary,
                            ),
                          ),
                        ] else
                          Text(
                            'No deadline set',
                            style: TextStyle(fontSize: 11, color: context.textMuted),
                          ),
                        if (accountName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.account_balance_wallet_outlined, size: 11, color: context.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              accountName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Action
              IconButton(
                icon: Icon(Icons.tune_rounded, size: 18, color: context.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => AddSavingGoalSheet.show(context, goalToEdit: goal),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amounts Row & Percentage Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$symbol ${CurrencyInputFormatter.format(goal.currentAmount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    'Target: $symbol ${CurrencyInputFormatter.format(goal.targetAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.teal.withValues(alpha: 0.18)
                      : (context.isDark ? accentColor.withValues(alpha: 0.15) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompleted ? AppColors.teal : (context.isDark ? accentColor.withValues(alpha: 0.4) : context.cardBorder),
                  ),
                ),
                child: Text(
                  isCompleted ? 'Goal Reached! 🎉' : '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? AppColors.teal : contrastAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.teal : accentColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Deposit / Withdraw Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textPrimary,
                side: BorderSide(color: context.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: context.inputBg,
              ),
              onPressed: () => DepositSavingGoalDialog.show(context, goal),
              icon: Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: isCompleted ? AppColors.teal : context.accentIconColor,
              ),
              label: Text(
                isCompleted ? 'Manage Funds' : '+ Add / Withdraw Funds',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.savings_outlined, size: 30, color: context.accentIconColor),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedTabIndex == 0
                  ? 'No active saving goals yet'
                  : 'No completed goals yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Set a new goal and start saving towards what matters most!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
              onPressed: () => AddSavingGoalSheet.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Create First Goal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
