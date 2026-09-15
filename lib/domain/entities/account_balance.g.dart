// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountBalance _$AccountBalanceFromJson(Map<String, dynamic> json) =>
    _AccountBalance(
      accountId: json['account_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: json['currency'] as String,
      balance: json['balance'] as num,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$AccountBalanceToJson(_AccountBalance instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'name': instance.name,
      'type': instance.type,
      'currency': instance.currency,
      'balance': instance.balance,
      'is_active': instance.isActive,
    };
