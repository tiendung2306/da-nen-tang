// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginData _$LoginDataFromJson(Map<String, dynamic> json) => LoginData(
      userInfo: UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$LoginDataToJson(LoginData instance) => <String, dynamic>{
      'userInfo': instance.userInfo,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
    };
