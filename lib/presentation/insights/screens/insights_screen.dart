import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../core/widgets/circular_progress_badge.dart';
import '../../../core/widgets/mini_bar_chart.dart';
import '../../../core/widgets/segmented_progress_bar.dart';
import '../../reports/providers/report_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(monthlyExpensesProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              const Text(
                'Reports & Insights',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Financial statistics and spending trends for this month',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 20),

              // Monthly Cashflow Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Monthly Cash Flow',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Net Cashflow: +Rp 4,250,000',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                    SizedBox(height: 18),
                    MiniBarChart(
                      height: 48,
                      barCount: 24,
                      barColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Breakdown Card from VIEW monthly_expense_by_category
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    expensesAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const SegmentedProgressBar(
                            height: 8,
                            items: [
                              SegmentItem(label: 'Food', value: 45, color: AppColors.primary),
                              SegmentItem(label: 'Transport', value: 20, color: AppColors.teal),
                              SegmentItem(label: 'Utilities', value: 15, color: AppColors.orange),
                              SegmentItem(label: 'Others', value: 20, color: AppColors.blue),
                            ],
                          );
                        }

                        final colors = [
                          AppColors.primary,
                          AppColors.teal,
                          AppColors.orange,
                          AppColors.blue,
                          AppColors.pink,
                          AppColors.yellow,
                        ];

                        final segments = items.asMap().entries.map((e) {
                          final idx = e.key;
                          final item = e.value;
                          return SegmentItem(
                            label: item.categoryName,
                            value: item.totalIdr,
                            color: colors[idx % colors.length],
                          );
                        }).toList();

                        return SegmentedProgressBar(
                          height: 8,
                          items: segments,
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppColors.primary),
                      error: (_, _) => const Text(
                        'No expense data available',
                        style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Savings Goal Progress Card
              GlassCard(
                child: Row(
                  children: const [
                    CircularProgressBadge(
                      percentage: 0.72,
                      size: 58,
                      progressColor: AppColors.teal,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Fund Savings Goal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rp 14,400,000 of Rp 20,000,000 (72%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
