// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavingGoal _$SavingGoalFromJson(Map<String, dynamic> json) => _SavingGoal(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  accountId: json['account_id'] as String?,
  name: json['name'] as String,
  targetAmount: json['target_amount'] as num,
  currentAmount: json['current_amount'] as num? ?? 0,
  currency: json['currency'] as String,
  targetDate: json['target_date'] as String?,
  icon: json['icon'] as String? ?? 'savings',
  color: json['color'] as String? ?? '#CCFF00',
  isCompleted: json['is_completed'] as bool? ?? false,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$SavingGoalToJson(_SavingGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'account_id': instance.accountId,
      'name': instance.name,
      'target_amount': instance.targetAmount,
      'current_amount': instance.currentAmount,
      'currency': instance.currency,
      'target_date': instance.targetDate,
      'icon': instance.icon,
      'color': instance.color,
      'is_completed': instance.isCompleted,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
