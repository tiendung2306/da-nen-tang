import 'package:json_annotation/json_annotation.dart';

part 'family_invitation_model.g.dart';

@JsonSerializable()
class FamilyInvitation {
  final int id;
  final int familyId;
  final String familyName;
  final InviterInfo inviter;
  final InviteeInfo? invitee;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.inviter,
    this.invitee,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory FamilyInvitation.fromJson(Map<String, dynamic> json) => _$FamilyInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$FamilyInvitationToJson(this);
}

@JsonSerializable()
class InviterInfo {
  final int id;
  final String username;
  final String fullName;
  final String? avatarUrl;

  InviterInfo({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
  });

  factory InviterInfo.fromJson(Map<String, dynamic> json) => _$InviterInfoFromJson(json);
  Map<String, dynamic> toJson() => _$InviterInfoToJson(this);
}

@JsonSerializable()
class InviteeInfo {
  final int id;
  final String username;
  final String fullName;
  final String? avatarUrl;

  InviteeInfo({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
  });

  factory InviteeInfo.fromJson(Map<String, dynamic> json) => _$InviteeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$InviteeInfoToJson(this);
}
