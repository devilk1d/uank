// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transfer _$TransferFromJson(Map<String, dynamic> json) => _Transfer(
  id: json['id'] as String,
  fromAccountId: json['from_account_id'] as String,
  toAccountId: json['to_account_id'] as String,
  amountFrom: json['amount_from'] as num,
  amountTo: json['amount_to'] as num,
  exchangeRate: json['exchange_rate'] as num,
  transferDate: DateTime.parse(json['transfer_date'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$TransferToJson(_Transfer instance) => <String, dynamic>{
  'id': instance.id,
  'from_account_id': instance.fromAccountId,
  'to_account_id': instance.toAccountId,
  'amount_from': instance.amountFrom,
  'amount_to': instance.amountTo,
  'exchange_rate': instance.exchangeRate,
  'transfer_date': instance.transferDate.toIso8601String(),
  'notes': instance.notes,
};
