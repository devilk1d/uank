// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExchangeRate _$ExchangeRateFromJson(Map<String, dynamic> json) =>
    _ExchangeRate(
      id: json['id'] as String,
      fromCurrency: json['from_currency'] as String,
      toCurrency: json['to_currency'] as String,
      rate: json['rate'] as num,
      source: json['source'] as String,
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );

Map<String, dynamic> _$ExchangeRateToJson(_ExchangeRate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from_currency': instance.fromCurrency,
      'to_currency': instance.toCurrency,
      'rate': instance.rate,
      'source': instance.source,
      'fetched_at': instance.fetchedAt.toIso8601String(),
    };
