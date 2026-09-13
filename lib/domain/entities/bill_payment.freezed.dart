// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillPayment {

 String get id;@JsonKey(name: 'bill_id') String get billId;@JsonKey(name: 'period_month') DateTime get periodMonth;@JsonKey(name: 'amount_paid') num? get amountPaid;@JsonKey(name: 'paid_date') DateTime? get paidDate; String get status;
/// Create a copy of BillPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillPaymentCopyWith<BillPayment> get copyWith => _$BillPaymentCopyWithImpl<BillPayment>(this as BillPayment, _$identity);

  /// Serializes this BillPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BillPayment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillPayment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.billId, _this.billId) || other.billId == _this.billId)&&(identical(other.periodMonth, _this.periodMonth) || other.periodMonth == _this.periodMonth)&&(identical(other.amountPaid, _this.amountPaid) || other.amountPaid == _this.amountPaid)&&(identical(other.paidDate, _this.paidDate) || other.paidDate == _this.paidDate)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BillPayment;
  return Object.hash(runtimeType,_this.id,_this.billId,_this.periodMonth,_this.amountPaid,_this.paidDate,_this.status);
}

@override
String toString() {
  final _this = this as BillPayment;
  return 'BillPayment(id: ${_this.id}, billId: ${_this.billId}, periodMonth: ${_this.periodMonth}, amountPaid: ${_this.amountPaid}, paidDate: ${_this.paidDate}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $BillPaymentCopyWith<$Res>  {
  factory $BillPaymentCopyWith(BillPayment value, $Res Function(BillPayment) _then) = _$BillPaymentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'bill_id') String billId,@JsonKey(name: 'period_month') DateTime periodMonth,@JsonKey(name: 'amount_paid') num? amountPaid,@JsonKey(name: 'paid_date') DateTime? paidDate, String status
});




}
/// @nodoc
class _$BillPaymentCopyWithImpl<$Res>
    implements $BillPaymentCopyWith<$Res> {
  _$BillPaymentCopyWithImpl(this._self, this._then);

  final BillPayment _self;
  final $Res Function(BillPayment) _then;

/// Create a copy of BillPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? billId = null,Object? periodMonth = null,Object? amountPaid = freezed,Object? paidDate = freezed,Object? status = null,}) {
  return _then(BillPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,amountPaid: freezed == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as num?,paidDate: freezed == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BillPayment].
extension BillPaymentPatterns on BillPayment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillPayment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillPayment value)  $default,){
final _that = this;
switch (_that) {
case _BillPayment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillPayment value)?  $default,){
final _that = this;
switch (_that) {
case _BillPayment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bill_id')  String billId, @JsonKey(name: 'period_month')  DateTime periodMonth, @JsonKey(name: 'amount_paid')  num? amountPaid, @JsonKey(name: 'paid_date')  DateTime? paidDate,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillPayment() when $default != null:
return $default(_that.id,_that.billId,_that.periodMonth,_that.amountPaid,_that.paidDate,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'bill_id')  String billId, @JsonKey(name: 'period_month')  DateTime periodMonth, @JsonKey(name: 'amount_paid')  num? amountPaid, @JsonKey(name: 'paid_date')  DateTime? paidDate,  String status)  $default,) {final _that = this;
switch (_that) {
case _BillPayment():
return $default(_that.id,_that.billId,_that.periodMonth,_that.amountPaid,_that.paidDate,_that.status);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'bill_id')  String billId, @JsonKey(name: 'period_month')  DateTime periodMonth, @JsonKey(name: 'amount_paid')  num? amountPaid, @JsonKey(name: 'paid_date')  DateTime? paidDate,  String status)?  $default,) {final _that = this;
switch (_that) {
case _BillPayment() when $default != null:
return $default(_that.id,_that.billId,_that.periodMonth,_that.amountPaid,_that.paidDate,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillPayment implements BillPayment {
  const _BillPayment({required this.id, @JsonKey(name: 'bill_id') required this.billId, @JsonKey(name: 'period_month') required this.periodMonth, @JsonKey(name: 'amount_paid') this.amountPaid, @JsonKey(name: 'paid_date') this.paidDate, this.status = 'pending'});
  factory _BillPayment.fromJson(Map<String, dynamic> json) => _$BillPaymentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'bill_id') final  String billId;
@override@JsonKey(name: 'period_month') final  DateTime periodMonth;
@override@JsonKey(name: 'amount_paid') final  num? amountPaid;
@override@JsonKey(name: 'paid_date') final  DateTime? paidDate;
@override@JsonKey() final  String status;

/// Create a copy of BillPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillPaymentCopyWith<_BillPayment> get copyWith => __$BillPaymentCopyWithImpl<_BillPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.amountPaid, amountPaid) || other.amountPaid == amountPaid)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,billId,periodMonth,amountPaid,paidDate,status);
}

@override
String toString() {
    return 'BillPayment(id: $id, billId: $billId, periodMonth: $periodMonth, amountPaid: $amountPaid, paidDate: $paidDate, status: $status)';
}


}

/// @nodoc
abstract mixin class _$BillPaymentCopyWith<$Res> implements $BillPaymentCopyWith<$Res> {
  factory _$BillPaymentCopyWith(_BillPayment value, $Res Function(_BillPayment) _then) = __$BillPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'bill_id') String billId,@JsonKey(name: 'period_month') DateTime periodMonth,@JsonKey(name: 'amount_paid') num? amountPaid,@JsonKey(name: 'paid_date') DateTime? paidDate, String status
});




}
/// @nodoc
class __$BillPaymentCopyWithImpl<$Res>
    implements _$BillPaymentCopyWith<$Res> {
  __$BillPaymentCopyWithImpl(this._self, this._then);

  final _BillPayment _self;
  final $Res Function(_BillPayment) _then;

/// Create a copy of BillPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? billId = null,Object? periodMonth = null,Object? amountPaid = freezed,Object? paidDate = freezed,Object? status = null,}) {
  return _then(_BillPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as DateTime,amountPaid: freezed == amountPaid ? _self.amountPaid : amountPaid // ignore: cast_nullable_to_non_nullable
as num?,paidDate: freezed == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
