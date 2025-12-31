// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) => Family(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['imageUrl'] as String?,
      inviteCode: json['inviteCode'] as String?,
      createdBy: json['createdBy'] == null
          ? null
          : FamilyCreator.fromJson(json['createdBy'] as Map<String, dynamic>),
      memberCount: (json['memberCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'imageUrl': instance.avatarUrl,
      'inviteCode': instance.inviteCode,
      'createdBy': instance.createdBy,
      'memberCount': instance.memberCount,
      'createdAt': instance.createdAt,
    };

FamilyCreator _$FamilyCreatorFromJson(Map<String, dynamic> json) =>
    FamilyCreator(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
    );

Map<String, dynamic> _$FamilyCreatorToJson(FamilyCreator instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
    };

FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) => FamilyMember(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$FamilyMemberToJson(FamilyMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'email': instance.email,
      'role': instance.role,
      'nickname': instance.nickname,
      'avatarUrl': instance.avatarUrl,
      'joinedAt': instance.joinedAt?.toIso8601String(),
    };
