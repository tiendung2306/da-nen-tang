import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class LoginData {
  final UserInfo userInfo;
  // FIX: Added the missing accessToken field
  final String accessToken;
  final String refreshToken;

  LoginData({required this.userInfo, required this.accessToken, required this.refreshToken});

  factory LoginData.fromJson(Map<String, dynamic> json) => _$LoginDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}

@JsonSerializable()
class UserInfo {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String? avatarUrl;

  UserInfo({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.avatarUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}
