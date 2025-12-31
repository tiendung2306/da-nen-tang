import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

// NOTE: The name is AppNotification to avoid conflict with Flutter's Notification
@JsonSerializable()
class AppNotification {
  final int id;
  final String type;
  final bool read;
  final String message;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.read,
    required this.message,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      read: read ?? this.read,
      message: message,
      createdAt: createdAt,
    );
  }
}

@JsonSerializable(genericArgumentFactories: true)
class PaginatedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PaginatedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);
}

@JsonSerializable()
class NotificationCount {
  final int total;
  final int unread;

  const NotificationCount({required this.total, required this.unread});

  factory NotificationCount.fromJson(Map<String, dynamic> json) => _$NotificationCountFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationCountToJson(this);
}
