// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  accountId: json['account_id'] as String,
  categoryId: json['category_id'] as String?,
  type: json['type'] as String,
  amount: json['amount'] as num,
  amountIdr: json['amount_idr'] as num?,
  description: json['description'] as String?,
  transactionDate: DateTime.parse(json['transaction_date'] as String),
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'category_id': instance.categoryId,
      'type': instance.type,
      'amount': instance.amount,
      'amount_idr': instance.amountIdr,
      'description': instance.description,
      'transaction_date': instance.transactionDate.toIso8601String(),
    };
