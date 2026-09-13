import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill.freezed.dart';
part 'bill.g.dart';

@freezed
abstract class Bill with _$Bill {
  const factory Bill({
    required String id,
    required String name,
    required num amount,
    required String currency,
    @JsonKey(name: 'due_day') required int dueDay,
    @JsonKey(name: 'account_id') String? accountId,
    @JsonKey(name: 'reminder_days_before') @Default(3) int reminderDaysBefore,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Bill;

  factory Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);
}