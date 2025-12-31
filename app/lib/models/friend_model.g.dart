// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendRequest _$FriendRequestFromJson(Map<String, dynamic> json) =>
    FriendRequest(
      id: (json['id'] as num).toInt(),
      requester: json['requester'] == null
          ? null
          : UserInfo.fromJson(json['requester'] as Map<String, dynamic>),
      addressee: json['addressee'] == null
          ? null
          : UserInfo.fromJson(json['addressee'] as Map<String, dynamic>),
      status: json['status'] as String,
    );

Map<String, dynamic> _$FriendRequestToJson(FriendRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requester': instance.requester,
      'addressee': instance.addressee,
      'status': instance.status,
    };

FriendStatusResponse _$FriendStatusResponseFromJson(
        Map<String, dynamic> json) =>
    FriendStatusResponse(
      status: json['status'] as String?,
    );

Map<String, dynamic> _$FriendStatusResponseToJson(
        FriendStatusResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
    };
