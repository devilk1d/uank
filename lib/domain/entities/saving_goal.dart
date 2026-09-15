import 'package:freezed_annotation/freezed_annotation.dart';

part 'saving_goal.freezed.dart';
part 'saving_goal.g.dart';

@freezed
abstract class SavingGoal with _$SavingGoal {
  const factory SavingGoal({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    required String name,
    @JsonKey(name: 'target_amount') required num targetAmount,
    @JsonKey(name: 'current_amount') @Default(0) num currentAmount,
    required String currency,
    @JsonKey(name: 'target_date') String? targetDate,
    @Default('savings') String icon,
    @Default('#CCFF00') String color,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _SavingGoal;

  factory SavingGoal.fromJson(Map<String, dynamic> json) => _$SavingGoalFromJson(json);
}
