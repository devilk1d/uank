import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_token.freezed.dart';
part 'device_token.g.dart';

@freezed
abstract class DeviceToken with _$DeviceToken {
  const factory DeviceToken({
    required String id,
    @JsonKey(name: 'fcm_token') required String fcmToken,
    required String platform, // 'android' | 'ios' | 'web'
  }) = _DeviceToken;

  factory DeviceToken.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenFromJson(json);
}