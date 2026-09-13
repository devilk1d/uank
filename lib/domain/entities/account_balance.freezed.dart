// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountBalance {

@JsonKey(name: 'account_id') String get accountId; String get name; String get type; String get currency; num get balance;
/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountBalanceCopyWith<AccountBalance> get copyWith => _$AccountBalanceCopyWithImpl<AccountBalance>(this as AccountBalance, _$identity);

  /// Serializes this AccountBalance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AccountBalance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountBalance&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.balance, _this.balance) || other.balance == _this.balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AccountBalance;
  return Object.hash(runtimeType,_this.accountId,_this.name,_this.type,_this.currency,_this.balance);
}

@override
String toString() {
  final _this = this as AccountBalance;
  return 'AccountBalance(accountId: ${_this.accountId}, name: ${_this.name}, type: ${_this.type}, currency: ${_this.currency}, balance: ${_this.balance})';
}


}

/// @nodoc
abstract mixin class $AccountBalanceCopyWith<$Res>  {
  factory $AccountBalanceCopyWith(AccountBalance value, $Res Function(AccountBalance) _then) = _$AccountBalanceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'account_id') String accountId, String name, String type, String currency, num balance
});




}
/// @nodoc
class _$AccountBalanceCopyWithImpl<$Res>
    implements $AccountBalanceCopyWith<$Res> {
  _$AccountBalanceCopyWithImpl(this._self, this._then);

  final AccountBalance _self;
  final $Res Function(AccountBalance) _then;

/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? name = null,Object? type = null,Object? currency = null,Object? balance = null,}) {
  return _then(AccountBalance(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountBalance].
extension AccountBalancePatterns on AccountBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountBalance value)  $default,){
final _that = this;
switch (_that) {
case _AccountBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountBalance value)?  $default,){
final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId,  String name,  String type,  String currency,  num balance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
return $default(_that.accountId,_that.name,_that.type,_that.currency,_that.balance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId,  String name,  String type,  String currency,  num balance)  $default,) {final _that = this;
switch (_that) {
case _AccountBalance():
return $default(_that.accountId,_that.name,_that.type,_that.currency,_that.balance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'account_id')  String accountId,  String name,  String type,  String currency,  num balance)?  $default,) {final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
return $default(_that.accountId,_that.name,_that.type,_that.currency,_that.balance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountBalance implements AccountBalance {
  const _AccountBalance({@JsonKey(name: 'account_id') required this.accountId, required this.name, required this.type, required this.currency, required this.balance});
  factory _AccountBalance.fromJson(Map<String, dynamic> json) => _$AccountBalanceFromJson(json);

@override@JsonKey(name: 'account_id') final  String accountId;
@override final  String name;
@override final  String type;
@override final  String currency;
@override final  num balance;

/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountBalanceCopyWith<_AccountBalance> get copyWith => __$AccountBalanceCopyWithImpl<_AccountBalance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountBalanceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountBalance&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.balance, balance) || other.balance == balance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accountId,name,type,currency,balance);
}

@override
String toString() {
    return 'AccountBalance(accountId: $accountId, name: $name, type: $type, currency: $currency, balance: $balance)';
}


}

/// @nodoc
abstract mixin class _$AccountBalanceCopyWith<$Res> implements $AccountBalanceCopyWith<$Res> {
  factory _$AccountBalanceCopyWith(_AccountBalance value, $Res Function(_AccountBalance) _then) = __$AccountBalanceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'account_id') String accountId, String name, String type, String currency, num balance
});




}
/// @nodoc
class __$AccountBalanceCopyWithImpl<$Res>
    implements _$AccountBalanceCopyWith<$Res> {
  __$AccountBalanceCopyWithImpl(this._self, this._then);

  final _AccountBalance _self;
  final $Res Function(_AccountBalance) _then;

/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? name = null,Object? type = null,Object? currency = null,Object? balance = null,}) {
  return _then(_AccountBalance(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
