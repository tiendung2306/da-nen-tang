import 'package:json_annotation/json_annotation.dart';

part 'family_model.g.dart';

@JsonSerializable()
class Family {
  final int id;
  final String name;
  final String? avatarUrl;
  // Added leaderName to match the new UI design.
  // This field should be provided by the backend API.
  final String? leaderName;

  Family({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.leaderName,
  });

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyToJson(this);
}

@JsonSerializable()
class FamilyMember {
  final int id;
  final String fullName;
  final String role;
  final String? avatarUrl;

  FamilyMember({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return FamilyMember(
      id: user['id'] as int,
      fullName: user['fullName'] as String,
      role: json['role'] as String,
      avatarUrl: user['avatarUrl'] as String?,
    );
  }
}
