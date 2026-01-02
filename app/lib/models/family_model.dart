import 'package:json_annotation/json_annotation.dart';

part 'family_model.g.dart';

@JsonSerializable()
class Family {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'imageUrl')
  final String? avatarUrl;
  final String? inviteCode;
  final FamilyCreator? createdBy;
  final int? memberCount;
  // FIX: Changed to String? to match the API response
  final String? createdAt;

  String? get leaderName => createdBy?.fullName;

  const Family({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.inviteCode,
    this.createdBy,
    this.memberCount,
    this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyToJson(this);

  // Override == và hashCode để DropdownButton có thể so sánh đúng
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Family && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class FamilyCreator {
  final int id;
  final String username;
  final String fullName;

  const FamilyCreator({
    required this.id,
    required this.username,
    required this.fullName,
  });

  factory FamilyCreator.fromJson(Map<String, dynamic> json) => _$FamilyCreatorFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyCreatorToJson(this);
}

@JsonSerializable()
class FamilyMember {
  final int id;
  final String username;
  final String fullName;
  final String? email;
  final String role;
  final String? nickname;
  final String? avatarUrl;
  final DateTime? joinedAt;

  const FamilyMember({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    required this.role,
    this.nickname,
    this.avatarUrl,
    this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user') && json['user'] != null) {
      final user = json['user'] as Map<String, dynamic>;
      return FamilyMember(
        id: user['id'] as int,
        username: user['username'] as String? ?? '',
        fullName: user['fullName'] as String? ?? user['username'] as String? ?? '',
        email: user['email'] as String?,
        role: json['role'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: user['avatarUrl'] as String?,
        joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      );
    } else {
      return FamilyMember(
        id: json['userId'] as int,
        username: json['username'] as String? ?? '',
        fullName: json['fullName'] as String? ?? json['username'] as String? ?? '',
        email: json['email'] as String?,
        role: json['role'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      );
    }
  }
}
