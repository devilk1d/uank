import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate.freezed.dart';
part 'exchange_rate.g.dart';

@freezed
abstract class ExchangeRate with _$ExchangeRate {
  const factory ExchangeRate({
    required String id,
    @JsonKey(name: 'from_currency') required String fromCurrency,
    @JsonKey(name: 'to_currency') required String toCurrency,
    required num rate,
    required String source, // 'wise' | 'flip' | 'manual'
    @JsonKey(name: 'fetched_at') required DateTime fetchedAt,
  }) = _ExchangeRate;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateFromJson(json);
}