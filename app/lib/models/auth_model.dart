import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class UserInfo {
  final int id;
  final String username;
  final String? email;
  final String fullName;
  final String? avatarUrl;
  final bool? isActive;
  // FIX: Made roles nullable and provided a default value.
  final List<String>? roles;

  String get name => fullName;

  UserInfo({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    this.avatarUrl,
    this.isActive = false,
    this.roles = const [], // Default to an empty list if not provided
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class LoginData {
  @JsonKey(name: 'accessToken')
  final String token;

  @JsonKey(name: 'user')
  final UserInfo userInfo;

  LoginData({required this.token, required this.userInfo});

  factory LoginData.fromJson(Map<String, dynamic> json) => _$LoginDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}
