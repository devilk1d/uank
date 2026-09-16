import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_card.dart';
import '../../../domain/entities/transaction.dart';
import '../../transactions/providers/transaction_providers.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: context.isDark ? AppColors.primary : const Color(0xFF15803D),
            backgroundColor: context.cardBg,
            onRefresh: () async {
              ref.invalidate(transactionsProvider);
              await ref.read(transactionsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                transactionsAsync.when(
                  data: (transactions) => transactions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Text(
                              'No activity recorded yet.',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        )
                      : Column(
                          children: transactions
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ActivityItem(transaction: t),
                                  ))
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Text('Error: $e', style: const TextStyle(color: AppColors.red)),
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

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isExpense ? AppColors.red : (context.isDark ? AppColors.green : const Color(0xFF059669))).withValues(alpha: 0.15),
              border: Border.all(
                color: (isExpense ? AppColors.red : (context.isDark ? AppColors.green : const Color(0xFF059669))).withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
              size: 18,
              color: isExpense ? AppColors.red : (context.isDark ? AppColors.green : const Color(0xFF059669)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Transaction',
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
                  transaction.type.toUpperCase(),
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
            '${isExpense ? '-' : '+'}${transaction.amount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isExpense ? AppColors.red : context.incomeColor,
            ),
          ),
        ],
      ),
    );
  }
}
