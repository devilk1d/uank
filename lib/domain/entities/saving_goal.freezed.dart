// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saving_goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavingGoal {

 String get id;@JsonKey(name: 'user_id') String? get userId; String get name;@JsonKey(name: 'target_amount') num get targetAmount;@JsonKey(name: 'current_amount') num get currentAmount; String get currency;@JsonKey(name: 'target_date') String? get targetDate; String get icon; String get color;@JsonKey(name: 'is_completed') bool get isCompleted;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;
/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavingGoalCopyWith<SavingGoal> get copyWith => _$SavingGoalCopyWithImpl<SavingGoal>(this as SavingGoal, _$identity);

  /// Serializes this SavingGoal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SavingGoal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavingGoal&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.targetAmount, _this.targetAmount) || other.targetAmount == _this.targetAmount)&&(identical(other.currentAmount, _this.currentAmount) || other.currentAmount == _this.currentAmount)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.targetDate, _this.targetDate) || other.targetDate == _this.targetDate)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.isCompleted, _this.isCompleted) || other.isCompleted == _this.isCompleted)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SavingGoal;
  return Object.hash(runtimeType,_this.id,_this.userId,_this.name,_this.targetAmount,_this.currentAmount,_this.currency,_this.targetDate,_this.icon,_this.color,_this.isCompleted,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as SavingGoal;
  return 'SavingGoal(id: ${_this.id}, userId: ${_this.userId}, name: ${_this.name}, targetAmount: ${_this.targetAmount}, currentAmount: ${_this.currentAmount}, currency: ${_this.currency}, targetDate: ${_this.targetDate}, icon: ${_this.icon}, color: ${_this.color}, isCompleted: ${_this.isCompleted}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $SavingGoalCopyWith<$Res>  {
  factory $SavingGoalCopyWith(SavingGoal value, $Res Function(SavingGoal) _then) = _$SavingGoalCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String? userId, String name,@JsonKey(name: 'target_amount') num targetAmount,@JsonKey(name: 'current_amount') num currentAmount, String currency,@JsonKey(name: 'target_date') String? targetDate, String icon, String color,@JsonKey(name: 'is_completed') bool isCompleted,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class _$SavingGoalCopyWithImpl<$Res>
    implements $SavingGoalCopyWith<$Res> {
  _$SavingGoalCopyWithImpl(this._self, this._then);

  final SavingGoal _self;
  final $Res Function(SavingGoal) _then;

/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = freezed,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? currency = null,Object? targetDate = freezed,Object? icon = null,Object? color = null,Object? isCompleted = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(SavingGoal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as num,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as num,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavingGoal].
extension SavingGoalPatterns on SavingGoal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavingGoal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavingGoal value)  $default,){
final _that = this;
switch (_that) {
case _SavingGoal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavingGoal value)?  $default,){
final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String? userId,  String name, @JsonKey(name: 'target_amount')  num targetAmount, @JsonKey(name: 'current_amount')  num currentAmount,  String currency, @JsonKey(name: 'target_date')  String? targetDate,  String icon,  String color, @JsonKey(name: 'is_completed')  bool isCompleted, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.targetAmount,_that.currentAmount,_that.currency,_that.targetDate,_that.icon,_that.color,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String? userId,  String name, @JsonKey(name: 'target_amount')  num targetAmount, @JsonKey(name: 'current_amount')  num currentAmount,  String currency, @JsonKey(name: 'target_date')  String? targetDate,  String icon,  String color, @JsonKey(name: 'is_completed')  bool isCompleted, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SavingGoal():
return $default(_that.id,_that.userId,_that.name,_that.targetAmount,_that.currentAmount,_that.currency,_that.targetDate,_that.icon,_that.color,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String? userId,  String name, @JsonKey(name: 'target_amount')  num targetAmount, @JsonKey(name: 'current_amount')  num currentAmount,  String currency, @JsonKey(name: 'target_date')  String? targetDate,  String icon,  String color, @JsonKey(name: 'is_completed')  bool isCompleted, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavingGoal() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.targetAmount,_that.currentAmount,_that.currency,_that.targetDate,_that.icon,_that.color,_that.isCompleted,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavingGoal implements SavingGoal {
  const _SavingGoal({required this.id, @JsonKey(name: 'user_id') this.userId, required this.name, @JsonKey(name: 'target_amount') required this.targetAmount, @JsonKey(name: 'current_amount') this.currentAmount = 0, required this.currency, @JsonKey(name: 'target_date') this.targetDate, this.icon = 'savings', this.color = '#CCFF00', @JsonKey(name: 'is_completed') this.isCompleted = false, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _SavingGoal.fromJson(Map<String, dynamic> json) => _$SavingGoalFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String? userId;
@override final  String name;
@override@JsonKey(name: 'target_amount') final  num targetAmount;
@override@JsonKey(name: 'current_amount') final  num currentAmount;
@override final  String currency;
@override@JsonKey(name: 'target_date') final  String? targetDate;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;
@override@JsonKey(name: 'is_completed') final  bool isCompleted;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;

/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavingGoalCopyWith<_SavingGoal> get copyWith => __$SavingGoalCopyWithImpl<_SavingGoal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavingGoalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavingGoal&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,userId,name,targetAmount,currentAmount,currency,targetDate,icon,color,isCompleted,createdAt,updatedAt);
}

@override
String toString() {
    return 'SavingGoal(id: $id, userId: $userId, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, currency: $currency, targetDate: $targetDate, icon: $icon, color: $color, isCompleted: $isCompleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SavingGoalCopyWith<$Res> implements $SavingGoalCopyWith<$Res> {
  factory _$SavingGoalCopyWith(_SavingGoal value, $Res Function(_SavingGoal) _then) = __$SavingGoalCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String? userId, String name,@JsonKey(name: 'target_amount') num targetAmount,@JsonKey(name: 'current_amount') num currentAmount, String currency,@JsonKey(name: 'target_date') String? targetDate, String icon, String color,@JsonKey(name: 'is_completed') bool isCompleted,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class __$SavingGoalCopyWithImpl<$Res>
    implements _$SavingGoalCopyWith<$Res> {
  __$SavingGoalCopyWithImpl(this._self, this._then);

  final _SavingGoal _self;
  final $Res Function(_SavingGoal) _then;

/// Create a copy of SavingGoal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = freezed,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? currency = null,Object? targetDate = freezed,Object? icon = null,Object? color = null,Object? isCompleted = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SavingGoal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as num,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as num,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
