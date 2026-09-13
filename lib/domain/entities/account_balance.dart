import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_balance.freezed.dart';
part 'account_balance.g.dart';

@freezed
abstract class AccountBalance with _$AccountBalance {
  const factory AccountBalance({
    @JsonKey(name: 'account_id') required String accountId,
    required String name,
    required String type,
    required String currency,
    required num balance,
  }) = _AccountBalance;

  factory AccountBalance.fromJson(Map<String, dynamic> json) =>
      _$AccountBalanceFromJson(json);
}