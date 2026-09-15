import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/saving_goal.dart';
import '../providers/saving_goal_providers.dart';
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

  static const Map<String, IconData> _iconMap = {
    'savings': Icons.savings_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'phone': Icons.phone_iphone_rounded,
    'car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'school': Icons.school_rounded,
    'fitness': Icons.fitness_center_rounded,
    'health': Icons.favorite_rounded,
    'vacation': Icons.beach_access_rounded,
    'celebration': Icons.celebration_rounded,
  };

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  IconData _getIconData(String iconKey) {
    return _iconMap[iconKey] ?? Icons.savings_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.darkCardBg,
            onRefresh: () async {
              ref.invalidate(savingGoalsProvider);
              await ref.read(savingGoalsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                // Header (Title & Add Goal CTA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saving Goals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.darkTextPrimary,
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
                                color: AppColors.darkCardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.darkCardBorder),
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
                                color: AppColors.darkCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.darkCardBorder),
                              ),
                              child: Row(
                                children: ['ALL', 'IDR', 'MYR'].map((cur) {
                                  final isSelected = _selectedCurrencyFilter == cur;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedCurrencyFilter = cur),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        cur,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
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
                        else
                          ...activeList.map((goal) => _buildGoalCard(goal)),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.red),
                          const SizedBox(height: 8),
                          Text('Failed to load goals: $e', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                          TextButton(
                            onPressed: () => ref.invalidate(savingGoalsProvider),
                            child: const Text('Retry', style: TextStyle(color: AppColors.primaryLight)),
                          ),
                        ],
                      ),
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
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primaryLight),
                  SizedBox(width: 6),
                  Text(
                    'Overall Savings Progress',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextSecondary,
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
              accentColor: AppColors.primary,
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Set your first saving goal to visualize your financial milestones.',
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'of $symbol ${CurrencyInputFormatter.format(target)} (${(progress * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextSecondary,
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
            backgroundColor: Colors.white.withValues(alpha: 0.08),
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
            color: isSelected ? Colors.black : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(SavingGoal goal) {
    final accentColor = _parseHexColor(goal.color);
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
        color: AppColors.darkCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted ? AppColors.teal.withValues(alpha: 0.5) : accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
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
                child: Icon(iconData, size: 22, color: accentColor),
              ),
              const SizedBox(width: 12),

              // Title & Deadline / Currency
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            goal.currency,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.darkTextSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (deadlineText != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: isCompleted ? AppColors.teal : AppColors.darkTextMuted),
                          const SizedBox(width: 4),
                          Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCompleted ? AppColors.teal : AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'No deadline set',
                        style: TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                      ),
                  ],
                ),
              ),

              // Edit Action
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.darkTextSecondary),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Target: $symbol ${CurrencyInputFormatter.format(goal.targetAmount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.teal.withValues(alpha: 0.18)
                      : accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompleted ? AppColors.teal : accentColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isCompleted ? 'Goal Reached! 🎉' : '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? AppColors.teal : accentColor,
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
              backgroundColor: Colors.white.withValues(alpha: 0.08),
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
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.white.withValues(alpha: 0.03),
              ),
              onPressed: () => DepositSavingGoalDialog.show(context, goal),
              icon: Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: isCompleted ? AppColors.teal : AppColors.primaryLight,
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
              child: const Icon(Icons.savings_outlined, size: 30, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedTabIndex == 0
                  ? 'No active saving goals yet'
                  : 'No completed goals yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Set a new goal and start saving towards what matters most!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
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
