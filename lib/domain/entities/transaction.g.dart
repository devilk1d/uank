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
  attachmentUrl: json['attachment_url'] as String?,
  transactionDate: DateTime.parse(json['transaction_date'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
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
      'attachment_url': instance.attachmentUrl,
      'transaction_date': instance.transactionDate.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };
