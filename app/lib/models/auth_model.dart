import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

// This model now matches the backend response for a user.
@JsonSerializable()
class UserInfo {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final bool isActive;
  final List<String> roles;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.roles,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

// This model now matches the 'data' object in the login response.
@JsonSerializable()
class LoginData {
  // The key from the backend is 'accessToken'.
  @JsonKey(name: 'accessToken')
  final String token;

  // The key from the backend is 'user'.
  @JsonKey(name: 'user')
  final UserInfo userInfo;

  LoginData({required this.token, required this.userInfo});

  factory LoginData.fromJson(Map<String, dynamic> json) => _$LoginDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}
