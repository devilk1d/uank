import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'category_id') String? categoryId,
    required String type, // 'income' | 'expense'
    required num amount,
    @JsonKey(name: 'amount_idr') num? amountIdr,
    String? description,
    @JsonKey(name: 'transaction_date') required DateTime transactionDate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}