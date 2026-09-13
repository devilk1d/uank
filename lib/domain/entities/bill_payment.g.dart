// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillPayment _$BillPaymentFromJson(Map<String, dynamic> json) => _BillPayment(
  id: json['id'] as String,
  billId: json['bill_id'] as String,
  periodMonth: DateTime.parse(json['period_month'] as String),
  amountPaid: json['amount_paid'] as num?,
  paidDate: json['paid_date'] == null
      ? null
      : DateTime.parse(json['paid_date'] as String),
  status: json['status'] as String? ?? 'pending',
);

Map<String, dynamic> _$BillPaymentToJson(_BillPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bill_id': instance.billId,
      'period_month': instance.periodMonth.toIso8601String(),
      'amount_paid': instance.amountPaid,
      'paid_date': instance.paidDate?.toIso8601String(),
      'status': instance.status,
    };
