import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    required String name,
    required String type, // 'bank' | 'ewallet' | 'cash'
    required String currency, // 'IDR' | 'MYR'
    @Default(true) bool isActive,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}