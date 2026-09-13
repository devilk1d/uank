import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_payment.freezed.dart';
part 'bill_payment.g.dart';

@freezed
abstract class BillPayment with _$BillPayment {
  const factory BillPayment({
    required String id,
    @JsonKey(name: 'bill_id') required String billId,
    @JsonKey(name: 'period_month') required DateTime periodMonth,
    @JsonKey(name: 'amount_paid') num? amountPaid,
    @JsonKey(name: 'paid_date') DateTime? paidDate,
    @Default('pending') String status, // 'pending' | 'paid' | 'overdue'
  }) = _BillPayment;

  factory BillPayment.fromJson(Map<String, dynamic> json) =>
      _$BillPaymentFromJson(json);
}