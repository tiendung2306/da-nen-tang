// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) => Family(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      leaderName: json['leaderName'] as String?,
    );

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'leaderName': instance.leaderName,
    };

FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) => FamilyMember(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$FamilyMemberToJson(FamilyMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'role': instance.role,
      'avatarUrl': instance.avatarUrl,
    };
