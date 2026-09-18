import '../../core/config/supabase_client.dart';
import '../../domain/entities/saving_goal.dart';

class SavingGoalRepository {
  Future<List<SavingGoal>> getAll() async {
    final rows = await supabase
        .from('saving_goals')
        .select()
        .order('created_at', ascending: false);
    return rows.map((row) => SavingGoal.fromJson(row)).toList();
  }

  Future<void> create(SavingGoal goal) async {
    final payload = <String, dynamic>{
      'name': goal.name,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'currency': goal.currency,
      'icon': goal.icon,
      'color': goal.color,
      'is_completed': goal.isCompleted,
    };
    if (goal.accountId != null && goal.accountId!.isNotEmpty) {
      payload['account_id'] = goal.accountId;
    }
    if (goal.targetDate != null && goal.targetDate!.isNotEmpty) {
      payload['target_date'] = goal.targetDate;
    }
    await supabase.from('saving_goals').insert(payload);
  }

  Future<void> update(SavingGoal goal) async {
    final payload = <String, dynamic>{
      'name': goal.name,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'currency': goal.currency,
      'icon': goal.icon,
      'color': goal.color,
      'is_completed': goal.isCompleted || goal.currentAmount >= goal.targetAmount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (goal.accountId != null) {
      payload['account_id'] = goal.accountId!.isEmpty ? null : goal.accountId;
    }
    if (goal.targetDate != null) {
      payload['target_date'] = goal.targetDate!.isEmpty ? null : goal.targetDate;
    }
    await supabase.from('saving_goals').update(payload).eq('id', goal.id);
  }

  Future<void> adjustAmount({
    required String id,
    required num deltaAmount,
  }) async {
    final res = await supabase.from('saving_goals').select().eq('id', id).single();
    final current = (res['current_amount'] as num?) ?? 0;
    final target = (res['target_amount'] as num?) ?? 0;
    final updatedAmount = (current + deltaAmount).clamp(0, double.infinity);
    final isCompleted = updatedAmount >= target;

    await supabase.from('saving_goals').update({
      'current_amount': updatedAmount,
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('saving_goals').delete().eq('id', id);
  }
}
