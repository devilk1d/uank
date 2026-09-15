import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entities/saving_goal.dart';
import '../../repository_providers.dart';

part 'saving_goal_providers.g.dart';

@riverpod
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

Future<void> deleteSavingGoal(WidgetRef ref, String id) async {
  final repo = ref.read(savingGoalRepositoryProvider);
  await repo.delete(id);
  ref.invalidate(savingGoalsProvider);
}
