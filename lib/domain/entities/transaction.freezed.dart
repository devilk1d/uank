// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

 String get id;@JsonKey(name: 'account_id') String get accountId;@JsonKey(name: 'category_id') String? get categoryId; String get type; num get amount;@JsonKey(name: 'amount_idr') num? get amountIdr; String? get description;@JsonKey(name: 'attachment_url') String? get attachmentUrl;@JsonKey(name: 'transaction_date') DateTime get transactionDate;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Transaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.amountIdr, _this.amountIdr) || other.amountIdr == _this.amountIdr)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.attachmentUrl, _this.attachmentUrl) || other.attachmentUrl == _this.attachmentUrl)&&(identical(other.transactionDate, _this.transactionDate) || other.transactionDate == _this.transactionDate)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transaction;
  return Object.hash(runtimeType,_this.id,_this.accountId,_this.categoryId,_this.type,_this.amount,_this.amountIdr,_this.description,_this.attachmentUrl,_this.transactionDate,_this.createdAt);
}

@override
String toString() {
  final _this = this as Transaction;
  return 'Transaction(id: ${_this.id}, accountId: ${_this.accountId}, categoryId: ${_this.categoryId}, type: ${_this.type}, amount: ${_this.amount}, amountIdr: ${_this.amountIdr}, description: ${_this.description}, attachmentUrl: ${_this.attachmentUrl}, transactionDate: ${_this.transactionDate}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'category_id') String? categoryId, String type, num amount,@JsonKey(name: 'amount_idr') num? amountIdr, String? description,@JsonKey(name: 'attachment_url') String? attachmentUrl,@JsonKey(name: 'transaction_date') DateTime transactionDate,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? categoryId = freezed,Object? type = null,Object? amount = null,Object? amountIdr = freezed,Object? description = freezed,Object? attachmentUrl = freezed,Object? transactionDate = null,Object? createdAt = freezed,}) {
  return _then(Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,amountIdr: freezed == amountIdr ? _self.amountIdr : amountIdr // ignore: cast_nullable_to_non_nullable
as num?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'category_id')  String? categoryId,  String type,  num amount, @JsonKey(name: 'amount_idr')  num? amountIdr,  String? description, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'transaction_date')  DateTime transactionDate, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.accountId,_that.categoryId,_that.type,_that.amount,_that.amountIdr,_that.description,_that.attachmentUrl,_that.transactionDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'category_id')  String? categoryId,  String type,  num amount, @JsonKey(name: 'amount_idr')  num? amountIdr,  String? description, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'transaction_date')  DateTime transactionDate, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.accountId,_that.categoryId,_that.type,_that.amount,_that.amountIdr,_that.description,_that.attachmentUrl,_that.transactionDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'category_id')  String? categoryId,  String type,  num amount, @JsonKey(name: 'amount_idr')  num? amountIdr,  String? description, @JsonKey(name: 'attachment_url')  String? attachmentUrl, @JsonKey(name: 'transaction_date')  DateTime transactionDate, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.accountId,_that.categoryId,_that.type,_that.amount,_that.amountIdr,_that.description,_that.attachmentUrl,_that.transactionDate,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction implements Transaction {
  const _Transaction({required this.id, @JsonKey(name: 'account_id') required this.accountId, @JsonKey(name: 'category_id') this.categoryId, required this.type, required this.amount, @JsonKey(name: 'amount_idr') this.amountIdr, this.description, @JsonKey(name: 'attachment_url') this.attachmentUrl, @JsonKey(name: 'transaction_date') required this.transactionDate, @JsonKey(name: 'created_at') this.createdAt});
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'account_id') final  String accountId;
@override@JsonKey(name: 'category_id') final  String? categoryId;
@override final  String type;
@override final  num amount;
@override@JsonKey(name: 'amount_idr') final  num? amountIdr;
@override final  String? description;
@override@JsonKey(name: 'attachment_url') final  String? attachmentUrl;
@override@JsonKey(name: 'transaction_date') final  DateTime transactionDate;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.amountIdr, amountIdr) || other.amountIdr == amountIdr)&&(identical(other.description, description) || other.description == description)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,accountId,categoryId,type,amount,amountIdr,description,attachmentUrl,transactionDate,createdAt);
}

@override
String toString() {
    return 'Transaction(id: $id, accountId: $accountId, categoryId: $categoryId, type: $type, amount: $amount, amountIdr: $amountIdr, description: $description, attachmentUrl: $attachmentUrl, transactionDate: $transactionDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'category_id') String? categoryId, String type, num amount,@JsonKey(name: 'amount_idr') num? amountIdr, String? description,@JsonKey(name: 'attachment_url') String? attachmentUrl,@JsonKey(name: 'transaction_date') DateTime transactionDate,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? categoryId = freezed,Object? type = null,Object? amount = null,Object? amountIdr = freezed,Object? description = freezed,Object? attachmentUrl = freezed,Object? transactionDate = null,Object? createdAt = freezed,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,amountIdr: freezed == amountIdr ? _self.amountIdr : amountIdr // ignore: cast_nullable_to_non_nullable
as num?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
