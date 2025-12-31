// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_invitation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyInvitation _$FamilyInvitationFromJson(Map<String, dynamic> json) =>
    FamilyInvitation(
      id: (json['id'] as num).toInt(),
      familyId: (json['familyId'] as num).toInt(),
      familyName: json['familyName'] as String,
      inviter: InviterInfo.fromJson(json['inviter'] as Map<String, dynamic>),
      invitee: json['invitee'] == null
          ? null
          : InviteeInfo.fromJson(json['invitee'] as Map<String, dynamic>),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
    );

Map<String, dynamic> _$FamilyInvitationToJson(FamilyInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'familyName': instance.familyName,
      'inviter': instance.inviter,
      'invitee': instance.invitee,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
    };

InviterInfo _$InviterInfoFromJson(Map<String, dynamic> json) => InviterInfo(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$InviterInfoToJson(InviterInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
    };

InviteeInfo _$InviteeInfoFromJson(Map<String, dynamic> json) => InviteeInfo(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$InviteeInfoToJson(InviteeInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
    };
