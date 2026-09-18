// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transfer {

 String get id;@JsonKey(name: 'from_account_id') String get fromAccountId;@JsonKey(name: 'to_account_id') String get toAccountId;@JsonKey(name: 'amount_from') num get amountFrom;@JsonKey(name: 'amount_to') num get amountTo;@JsonKey(name: 'exchange_rate') num get exchangeRate;@JsonKey(name: 'transfer_date') DateTime get transferDate; String? get notes;@JsonKey(name: 'attachment_url') String? get attachmentUrl;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferCopyWith<Transfer> get copyWith => _$TransferCopyWithImpl<Transfer>(this as Transfer, _$identity);

  /// Serializes this Transfer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Transfer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transfer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fromAccountId, _this.fromAccountId) || other.fromAccountId == _this.fromAccountId)&&(identical(other.toAccountId, _this.toAccountId) || other.toAccountId == _this.toAccountId)&&(identical(other.amountFrom, _this.amountFrom) || other.amountFrom == _this.amountFrom)&&(identical(other.amountTo, _this.amountTo) || other.amountTo == _this.amountTo)&&(identical(other.exchangeRate, _this.exchangeRate) || other.exchangeRate == _this.exchangeRate)&&(identical(other.transferDate, _this.transferDate) || other.transferDate == _this.transferDate)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.attachmentUrl, _this.attachmentUrl) || other.attachmentUrl == _this.attachmentUrl)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transfer;
  return Object.hash(runtimeType,_this.id,_this.fromAccountId,_this.toAccountId,_this.amountFrom,_this.amountTo,_this.exchangeRate,_this.transferDate,_this.notes,_this.attachmentUrl,_this.createdAt);
}

@override
String toString() {
  final _this = this as Transfer;
  return 'Transfer(id: ${_this.id}, fromAccountId: ${_this.fromAccountId}, toAccountId: ${_this.toAccountId}, amountFrom: ${_this.amountFrom}, amountTo: ${_this.amountTo}, exchangeRate: ${_this.exchangeRate}, transferDate: ${_this.transferDate}, notes: ${_this.notes}, attachmentUrl: ${_this.attachmentUrl}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $TransferCopyWith<$Res>  {
  factory $TransferCopyWith(Transfer value, $Res Function(Transfer) _then) = _$TransferCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'from_account_id') String fromAccountId,@JsonKey(name: 'to_account_id') String toAccountId,@JsonKey(name: 'amount_from') num amountFrom,@JsonKey(name: 'amount_to') num amountTo,@JsonKey(name: 'exchange_rate') num exchangeRate,@JsonKey(name: 'transfer_date') DateTime transferDate, String? notes,@JsonKey(name: 'attachment_url') String? attachmentUrl,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$TransferCopyWithImpl<$Res>
    implements $TransferCopyWith<$Res> {
  _$TransferCopyWithImpl(this._self, this._then);

  final Transfer _self;
  final $Res Function(Transfer) _then;

/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromAccountId = null,Object? toAccountId = null,Object? amountFrom = null,Object? amountTo = null,Object? exchangeRate = null,Object? transferDate = null,Object? notes = freezed,Object? attachmentUrl = freezed,Object? createdAt = freezed,}) {
  return _then(Transfer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: null == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as String,toAccountId: null == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String,amountFrom: null == amountFrom ? _self.amountFrom : amountFrom // ignore: cast_nullable_to_non_nullable
as num,amountTo: null == amountTo ? _self.amountTo : amountTo // ignore: cast_nullable_to_non_nullable
as num,exchangeRate: null == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as num,transferDate: null == transferDate ? _self.transferDate : transferDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transfer].
extension TransferPatterns on Transfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transfer value)  $default,){
final _that = this;
switch (_that) {
case _Transfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transfer value)?  $default,){
final _that = this;
switch (_that) {
case _Transfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'from_account_id')  String fromAccountId, @JsonKey(name: 'to_account_id')  String toAccountId, @JsonKey(name: 'amount_from')  num amountFrom, @JsonKey(name: 'amount_to')  num amountTo, @JsonKey(name: 'exchange_rate')  num exchangeRate, @JsonKey(name: 'transfer_date')  DateTime transferDate,  String? notes, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transfer() when $default != null:
return $default(_that.id,_that.fromAccountId,_that.toAccountId,_that.amountFrom,_that.amountTo,_that.exchangeRate,_that.transferDate,_that.notes,_that.attachmentUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'from_account_id')  String fromAccountId, @JsonKey(name: 'to_account_id')  String toAccountId, @JsonKey(name: 'amount_from')  num amountFrom, @JsonKey(name: 'amount_to')  num amountTo, @JsonKey(name: 'exchange_rate')  num exchangeRate, @JsonKey(name: 'transfer_date')  DateTime transferDate,  String? notes, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Transfer():
return $default(_that.id,_that.fromAccountId,_that.toAccountId,_that.amountFrom,_that.amountTo,_that.exchangeRate,_that.transferDate,_that.notes,_that.attachmentUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'from_account_id')  String fromAccountId, @JsonKey(name: 'to_account_id')  String toAccountId, @JsonKey(name: 'amount_from')  num amountFrom, @JsonKey(name: 'amount_to')  num amountTo, @JsonKey(name: 'exchange_rate')  num exchangeRate, @JsonKey(name: 'transfer_date')  DateTime transferDate,  String? notes, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Transfer() when $default != null:
return $default(_that.id,_that.fromAccountId,_that.toAccountId,_that.amountFrom,_that.amountTo,_that.exchangeRate,_that.transferDate,_that.notes,_that.attachmentUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transfer implements Transfer {
  const _Transfer({required this.id, @JsonKey(name: 'from_account_id') required this.fromAccountId, @JsonKey(name: 'to_account_id') required this.toAccountId, @JsonKey(name: 'amount_from') required this.amountFrom, @JsonKey(name: 'amount_to') required this.amountTo, @JsonKey(name: 'exchange_rate') required this.exchangeRate, @JsonKey(name: 'transfer_date') required this.transferDate, this.notes, @JsonKey(name: 'attachment_url') this.attachmentUrl, @JsonKey(name: 'created_at') this.createdAt});
  factory _Transfer.fromJson(Map<String, dynamic> json) => _$TransferFromJson(json);

@override final  String id;
@override@JsonKey(name: 'from_account_id') final  String fromAccountId;
@override@JsonKey(name: 'to_account_id') final  String toAccountId;
@override@JsonKey(name: 'amount_from') final  num amountFrom;
@override@JsonKey(name: 'amount_to') final  num amountTo;
@override@JsonKey(name: 'exchange_rate') final  num exchangeRate;
@override@JsonKey(name: 'transfer_date') final  DateTime transferDate;
@override final  String? notes;
@override@JsonKey(name: 'attachment_url') final  String? attachmentUrl;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferCopyWith<_Transfer> get copyWith => __$TransferCopyWithImpl<_Transfer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransferToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transfer&&(identical(other.id, id) || other.id == id)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.amountFrom, amountFrom) || other.amountFrom == amountFrom)&&(identical(other.amountTo, amountTo) || other.amountTo == amountTo)&&(identical(other.exchangeRate, exchangeRate) || other.exchangeRate == exchangeRate)&&(identical(other.transferDate, transferDate) || other.transferDate == transferDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fromAccountId,toAccountId,amountFrom,amountTo,exchangeRate,transferDate,notes,attachmentUrl,createdAt);
}

@override
String toString() {
    return 'Transfer(id: $id, fromAccountId: $fromAccountId, toAccountId: $toAccountId, amountFrom: $amountFrom, amountTo: $amountTo, exchangeRate: $exchangeRate, transferDate: $transferDate, notes: $notes, attachmentUrl: $attachmentUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TransferCopyWith<$Res> implements $TransferCopyWith<$Res> {
  factory _$TransferCopyWith(_Transfer value, $Res Function(_Transfer) _then) = __$TransferCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'from_account_id') String fromAccountId,@JsonKey(name: 'to_account_id') String toAccountId,@JsonKey(name: 'amount_from') num amountFrom,@JsonKey(name: 'amount_to') num amountTo,@JsonKey(name: 'exchange_rate') num exchangeRate,@JsonKey(name: 'transfer_date') DateTime transferDate, String? notes,@JsonKey(name: 'attachment_url') String? attachmentUrl,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$TransferCopyWithImpl<$Res>
    implements _$TransferCopyWith<$Res> {
  __$TransferCopyWithImpl(this._self, this._then);

  final _Transfer _self;
  final $Res Function(_Transfer) _then;

/// Create a copy of Transfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromAccountId = null,Object? toAccountId = null,Object? amountFrom = null,Object? amountTo = null,Object? exchangeRate = null,Object? transferDate = null,Object? notes = freezed,Object? attachmentUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_Transfer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromAccountId: null == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as String,toAccountId: null == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String,amountFrom: null == amountFrom ? _self.amountFrom : amountFrom // ignore: cast_nullable_to_non_nullable
as num,amountTo: null == amountTo ? _self.amountTo : amountTo // ignore: cast_nullable_to_non_nullable
as num,exchangeRate: null == exchangeRate ? _self.exchangeRate : exchangeRate // ignore: cast_nullable_to_non_nullable
as num,transferDate: null == transferDate ? _self.transferDate : transferDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
