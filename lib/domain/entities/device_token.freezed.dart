// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceToken {

 String get id;@JsonKey(name: 'fcm_token') String get fcmToken; String get platform;
/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceTokenCopyWith<DeviceToken> get copyWith => _$DeviceTokenCopyWithImpl<DeviceToken>(this as DeviceToken, _$identity);

  /// Serializes this DeviceToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceToken;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceToken&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fcmToken, _this.fcmToken) || other.fcmToken == _this.fcmToken)&&(identical(other.platform, _this.platform) || other.platform == _this.platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceToken;
  return Object.hash(runtimeType,_this.id,_this.fcmToken,_this.platform);
}

@override
String toString() {
  final _this = this as DeviceToken;
  return 'DeviceToken(id: ${_this.id}, fcmToken: ${_this.fcmToken}, platform: ${_this.platform})';
}


}

/// @nodoc
abstract mixin class $DeviceTokenCopyWith<$Res>  {
  factory $DeviceTokenCopyWith(DeviceToken value, $Res Function(DeviceToken) _then) = _$DeviceTokenCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'fcm_token') String fcmToken, String platform
});




}
/// @nodoc
class _$DeviceTokenCopyWithImpl<$Res>
    implements $DeviceTokenCopyWith<$Res> {
  _$DeviceTokenCopyWithImpl(this._self, this._then);

  final DeviceToken _self;
  final $Res Function(DeviceToken) _then;

/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fcmToken = null,Object? platform = null,}) {
  return _then(DeviceToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fcmToken: null == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceToken].
extension DeviceTokenPatterns on DeviceToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceToken value)  $default,){
final _that = this;
switch (_that) {
case _DeviceToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceToken value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'fcm_token')  String fcmToken,  String platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
return $default(_that.id,_that.fcmToken,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'fcm_token')  String fcmToken,  String platform)  $default,) {final _that = this;
switch (_that) {
case _DeviceToken():
return $default(_that.id,_that.fcmToken,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'fcm_token')  String fcmToken,  String platform)?  $default,) {final _that = this;
switch (_that) {
case _DeviceToken() when $default != null:
return $default(_that.id,_that.fcmToken,_that.platform);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceToken implements DeviceToken {
  const _DeviceToken({required this.id, @JsonKey(name: 'fcm_token') required this.fcmToken, required this.platform});
  factory _DeviceToken.fromJson(Map<String, dynamic> json) => _$DeviceTokenFromJson(json);

@override final  String id;
@override@JsonKey(name: 'fcm_token') final  String fcmToken;
@override final  String platform;

/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceTokenCopyWith<_DeviceToken> get copyWith => __$DeviceTokenCopyWithImpl<_DeviceToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceTokenToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceToken&&(identical(other.id, id) || other.id == id)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fcmToken,platform);
}

@override
String toString() {
    return 'DeviceToken(id: $id, fcmToken: $fcmToken, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$DeviceTokenCopyWith<$Res> implements $DeviceTokenCopyWith<$Res> {
  factory _$DeviceTokenCopyWith(_DeviceToken value, $Res Function(_DeviceToken) _then) = __$DeviceTokenCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'fcm_token') String fcmToken, String platform
});




}
/// @nodoc
class __$DeviceTokenCopyWithImpl<$Res>
    implements _$DeviceTokenCopyWith<$Res> {
  __$DeviceTokenCopyWithImpl(this._self, this._then);

  final _DeviceToken _self;
  final $Res Function(_DeviceToken) _then;

/// Create a copy of DeviceToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fcmToken = null,Object? platform = null,}) {
  return _then(_DeviceToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fcmToken: null == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
