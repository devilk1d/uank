import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.freezed.dart';
part 'transfer.g.dart';

@freezed
abstract class Transfer with _$Transfer {
  const factory Transfer({
    required String id,
    @JsonKey(name: 'from_account_id') required String fromAccountId,
    @JsonKey(name: 'to_account_id') required String toAccountId,
    @JsonKey(name: 'amount_from') required num amountFrom,
    @JsonKey(name: 'amount_to') required num amountTo,
    @JsonKey(name: 'exchange_rate') required num exchangeRate,
    @JsonKey(name: 'transfer_date') required DateTime transferDate,
    String? notes,
    @JsonKey(name: 'attachment_url') String? attachmentUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Transfer;

  factory Transfer.fromJson(Map<String, dynamic> json) =>
      _$TransferFromJson(json);
}