import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';

part 'friend_model.g.dart';

@JsonSerializable()
class FriendRequest {
  final int id;
  // FIX: Added requester and addressee to match the backend response.
  final UserInfo? requester;
  final UserInfo? addressee;
  final String status;

  FriendRequest({
    required this.id, 
    this.requester, 
    this.addressee, 
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => _$FriendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$FriendRequestToJson(this);
}

// Represents the status of a friendship with another user.
enum FriendshipStatus { friends, request_sent, request_received, not_friends }

@JsonSerializable()
class FriendStatusResponse {
  final String? status;

  FriendStatusResponse({this.status});

  FriendshipStatus get friendshipStatus {
    switch (status) {
      case 'friends':
        return FriendshipStatus.friends;
      case 'request_sent':
        return FriendshipStatus.request_sent;
      case 'request_received':
        return FriendshipStatus.request_received;
      default:
        return FriendshipStatus.not_friends;
    }
  }

  factory FriendStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$FriendStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FriendStatusResponseToJson(this);
}
