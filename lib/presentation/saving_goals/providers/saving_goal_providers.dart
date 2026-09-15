import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/saving_goal.dart';
import '../../../domain/entities/transaction.dart';
import '../../accounts/providers/account_providers.dart';
import '../../repository_providers.dart';
import '../../transactions/providers/transaction_providers.dart';

part 'saving_goal_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<SavingGoal>> savingGoals(Ref ref) {
  final repo = ref.watch(savingGoalRepositoryProvider);
  return repo.getAll();
}

Future<void> createSavingGoal(WidgetRef ref, SavingGoal goal) async {
  final repo = ref.read(savingGoalRepositoryProvider);
  await repo.create(goal);
  ref.invalidate(savingGoalsProvider);
}

Future<void> updateSavingGoal(WidgetRef ref, SavingGoal goal) async {
  final repo = ref.read(savingGoalRepositoryProvider);
  await repo.update(goal);
  ref.invalidate(savingGoalsProvider);
}

Future<void> adjustSavingGoalAmount(
  WidgetRef ref, {
  required String id,
  required num deltaAmount,
}) async {
  final repo = ref.read(savingGoalRepositoryProvider);
  await repo.adjustAmount(id: id, deltaAmount: deltaAmount);
  ref.invalidate(savingGoalsProvider);
}

Future<void> depositOrWithdrawSavingGoal(
  WidgetRef ref, {
  required SavingGoal goal,
  required String accountId,
  required num amount,
  required bool isDeposit,
}) async {
  final delta = isDeposit ? amount : -amount;
  final savingGoalRepo = ref.read(savingGoalRepositoryProvider);
  await savingGoalRepo.adjustAmount(id: goal.id, deltaAmount: delta);

  final txRepo = ref.read(transactionRepositoryProvider);
  final tx = Transaction(
    id: '',
    accountId: accountId,
    type: isDeposit ? 'expense' : 'income',
    amount: amount,
    description: isDeposit
        ? 'Deposit to Saving Goal: ${goal.name}'
        : 'Withdrawal from Saving Goal: ${goal.name}',
    transactionDate: DateTime.now(),
  );
  await txRepo.create(tx);

  ref.invalidate(savingGoalsProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(accountBalancesProvider);
}

Future<void> deleteSavingGoal(WidgetRef ref, String id) async {
  final repo = ref.read(savingGoalRepositoryProvider);
  await repo.delete(id);
  ref.invalidate(savingGoalsProvider);
}
