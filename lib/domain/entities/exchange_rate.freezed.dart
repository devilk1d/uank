// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExchangeRate {

 String get id;@JsonKey(name: 'from_currency') String get fromCurrency;@JsonKey(name: 'to_currency') String get toCurrency; num get rate; String get source;@JsonKey(name: 'fetched_at') DateTime get fetchedAt;
/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExchangeRateCopyWith<ExchangeRate> get copyWith => _$ExchangeRateCopyWithImpl<ExchangeRate>(this as ExchangeRate, _$identity);

  /// Serializes this ExchangeRate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExchangeRate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExchangeRate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fromCurrency, _this.fromCurrency) || other.fromCurrency == _this.fromCurrency)&&(identical(other.toCurrency, _this.toCurrency) || other.toCurrency == _this.toCurrency)&&(identical(other.rate, _this.rate) || other.rate == _this.rate)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.fetchedAt, _this.fetchedAt) || other.fetchedAt == _this.fetchedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExchangeRate;
  return Object.hash(runtimeType,_this.id,_this.fromCurrency,_this.toCurrency,_this.rate,_this.source,_this.fetchedAt);
}

@override
String toString() {
  final _this = this as ExchangeRate;
  return 'ExchangeRate(id: ${_this.id}, fromCurrency: ${_this.fromCurrency}, toCurrency: ${_this.toCurrency}, rate: ${_this.rate}, source: ${_this.source}, fetchedAt: ${_this.fetchedAt})';
}


}

/// @nodoc
abstract mixin class $ExchangeRateCopyWith<$Res>  {
  factory $ExchangeRateCopyWith(ExchangeRate value, $Res Function(ExchangeRate) _then) = _$ExchangeRateCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'from_currency') String fromCurrency,@JsonKey(name: 'to_currency') String toCurrency, num rate, String source,@JsonKey(name: 'fetched_at') DateTime fetchedAt
});




}
/// @nodoc
class _$ExchangeRateCopyWithImpl<$Res>
    implements $ExchangeRateCopyWith<$Res> {
  _$ExchangeRateCopyWithImpl(this._self, this._then);

  final ExchangeRate _self;
  final $Res Function(ExchangeRate) _then;

/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromCurrency = null,Object? toCurrency = null,Object? rate = null,Object? source = null,Object? fetchedAt = null,}) {
  return _then(ExchangeRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromCurrency: null == fromCurrency ? _self.fromCurrency : fromCurrency // ignore: cast_nullable_to_non_nullable
as String,toCurrency: null == toCurrency ? _self.toCurrency : toCurrency // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as num,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ExchangeRate].
extension ExchangeRatePatterns on ExchangeRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExchangeRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExchangeRate value)  $default,){
final _that = this;
switch (_that) {
case _ExchangeRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExchangeRate value)?  $default,){
final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'from_currency')  String fromCurrency, @JsonKey(name: 'to_currency')  String toCurrency,  num rate,  String source, @JsonKey(name: 'fetched_at')  DateTime fetchedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
return $default(_that.id,_that.fromCurrency,_that.toCurrency,_that.rate,_that.source,_that.fetchedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'from_currency')  String fromCurrency, @JsonKey(name: 'to_currency')  String toCurrency,  num rate,  String source, @JsonKey(name: 'fetched_at')  DateTime fetchedAt)  $default,) {final _that = this;
switch (_that) {
case _ExchangeRate():
return $default(_that.id,_that.fromCurrency,_that.toCurrency,_that.rate,_that.source,_that.fetchedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'from_currency')  String fromCurrency, @JsonKey(name: 'to_currency')  String toCurrency,  num rate,  String source, @JsonKey(name: 'fetched_at')  DateTime fetchedAt)?  $default,) {final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
return $default(_that.id,_that.fromCurrency,_that.toCurrency,_that.rate,_that.source,_that.fetchedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExchangeRate implements ExchangeRate {
  const _ExchangeRate({required this.id, @JsonKey(name: 'from_currency') required this.fromCurrency, @JsonKey(name: 'to_currency') required this.toCurrency, required this.rate, required this.source, @JsonKey(name: 'fetched_at') required this.fetchedAt});
  factory _ExchangeRate.fromJson(Map<String, dynamic> json) => _$ExchangeRateFromJson(json);

@override final  String id;
@override@JsonKey(name: 'from_currency') final  String fromCurrency;
@override@JsonKey(name: 'to_currency') final  String toCurrency;
@override final  num rate;
@override final  String source;
@override@JsonKey(name: 'fetched_at') final  DateTime fetchedAt;

/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExchangeRateCopyWith<_ExchangeRate> get copyWith => __$ExchangeRateCopyWithImpl<_ExchangeRate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExchangeRateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExchangeRate&&(identical(other.id, id) || other.id == id)&&(identical(other.fromCurrency, fromCurrency) || other.fromCurrency == fromCurrency)&&(identical(other.toCurrency, toCurrency) || other.toCurrency == toCurrency)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.source, source) || other.source == source)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fromCurrency,toCurrency,rate,source,fetchedAt);
}

@override
String toString() {
    return 'ExchangeRate(id: $id, fromCurrency: $fromCurrency, toCurrency: $toCurrency, rate: $rate, source: $source, fetchedAt: $fetchedAt)';
}


}

/// @nodoc
abstract mixin class _$ExchangeRateCopyWith<$Res> implements $ExchangeRateCopyWith<$Res> {
  factory _$ExchangeRateCopyWith(_ExchangeRate value, $Res Function(_ExchangeRate) _then) = __$ExchangeRateCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'from_currency') String fromCurrency,@JsonKey(name: 'to_currency') String toCurrency, num rate, String source,@JsonKey(name: 'fetched_at') DateTime fetchedAt
});




}
/// @nodoc
class __$ExchangeRateCopyWithImpl<$Res>
    implements _$ExchangeRateCopyWith<$Res> {
  __$ExchangeRateCopyWithImpl(this._self, this._then);

  final _ExchangeRate _self;
  final $Res Function(_ExchangeRate) _then;

/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromCurrency = null,Object? toCurrency = null,Object? rate = null,Object? source = null,Object? fetchedAt = null,}) {
  return _then(_ExchangeRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromCurrency: null == fromCurrency ? _self.fromCurrency : fromCurrency // ignore: cast_nullable_to_non_nullable
as String,toCurrency: null == toCurrency ? _self.toCurrency : toCurrency // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as num,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
