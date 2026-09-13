// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceToken _$DeviceTokenFromJson(Map<String, dynamic> json) => _DeviceToken(
  id: json['id'] as String,
  fcmToken: json['fcm_token'] as String,
  platform: json['platform'] as String,
);

Map<String, dynamic> _$DeviceTokenToJson(_DeviceToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fcm_token': instance.fcmToken,
      'platform': instance.platform,
    };
