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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              transactionsAsync.when(
                data: (transactions) => transactions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(color: AppColors.darkTextSecondary),
                          ),
                        ),
                      )
                    : Column(
                        children: transactions
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ActivityCard(transaction: t),
                                ))
                            .toList(),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('$e', style: const TextStyle(color: AppColors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isExpense ? AppColors.primary : AppColors.green)
                      .withValues(alpha: 0.15),
                ),
                child: Icon(
                  isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                  size: 18,
                  color: isExpense ? AppColors.primaryLight : AppColors.green,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? 'Transaction',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${isExpense ? '-' : '+'}\$${transaction.amount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isExpense ? AppColors.darkTextPrimary : AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}
