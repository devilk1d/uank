// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Bill _$BillFromJson(Map<String, dynamic> json) => _Bill(
  id: json['id'] as String,
  name: json['name'] as String,
  amount: json['amount'] as num,
  currency: json['currency'] as String,
  dueDay: (json['due_day'] as num).toInt(),
  accountId: json['account_id'] as String?,
  reminderDaysBefore: (json['reminder_days_before'] as num?)?.toInt() ?? 3,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$BillToJson(_Bill instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'amount': instance.amount,
  'currency': instance.currency,
  'due_day': instance.dueDay,
  'account_id': instance.accountId,
  'reminder_days_before': instance.reminderDaysBefore,
  'is_active': instance.isActive,
};
