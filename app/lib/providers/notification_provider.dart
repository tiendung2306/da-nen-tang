import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/notification_model.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = locator<ApiService>();

  List<NotificationItem> _notifications = [];
  NotificationCount _count = NotificationCount(total: 0, unread: 0);
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _showUnreadOnly = false;

  List<NotificationItem> get notifications => _notifications;
  NotificationCount get count => _count;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get showUnreadOnly => _showUnreadOnly;
  int get unreadCount => _count.unread;

  void setShowUnreadOnly(bool value) {
    if (_showUnreadOnly != value) {
      _showUnreadOnly = value;
      refresh();
    }
  }

  Future<void> fetchNotifications({bool loadMore = false}) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    _isLoading = true;
    _error = null;
    if (!loadMore) {
      _currentPage = 0;
      _notifications = [];
    }
    notifyListeners();

    try {
      final result = await _apiService.getNotifications(
        page: _currentPage,
        size: 20,
        unreadOnly: _showUnreadOnly,
      );

      if (loadMore) {
        _notifications.addAll(result.content);
      } else {
        _notifications = result.content;
      }

      _hasMore = !result.last;
      if (_hasMore) _currentPage++;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCount() async {
    try {
      _count = await _apiService.getNotificationCount();
      notifyListeners();
    } catch (e) {
      // Silent fail for count
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    await Future.wait([
      fetchNotifications(),
      fetchCount(),
    ]);
  }

  Future<void> markAsRead(List<int> ids) async {
    try {
      await _apiService.markNotificationsAsRead(ids);
      
      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (ids.contains(_notifications[i].id)) {
          _notifications[i] = NotificationItem(
            id: _notifications[i].id,
            title: _notifications[i].title,
            message: _notifications[i].message,
            type: _notifications[i].type,
            referenceType: _notifications[i].referenceType,
            referenceId: _notifications[i].referenceId,
            isRead: true,
            createdAt: _notifications[i].createdAt,
            readAt: DateTime.now(),
          );
        }
      }
      
      // Update count
      _count = NotificationCount(
        total: _count.total,
        unread: (_count.unread - ids.length).clamp(0, _count.total),
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // markAsUnread is not supported by current API
  // Comment this method if needed in future
  /*
  Future<void> markAsUnread(List<int> ids) async {
    try {
      await _apiService.markNotificationsAsUnread(ids);
      
      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (ids.contains(_notifications[i].id)) {
          _notifications[i] = NotificationItem(
            id: _notifications[i].id,
            title: _notifications[i].title,
            message: _notifications[i].message,
            type: _notifications[i].type,
            referenceType: _notifications[i].referenceType,
            referenceId: _notifications[i].referenceId,
            isRead: false,
            createdAt: _notifications[i].createdAt,
            readAt: null,
          );
        }
      }
      
      // Update count
      _count = NotificationCount(
        total: _count.total,
        unread: _count.unread + ids.length,
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  */

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      
      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = NotificationItem(
            id: _notifications[i].id,
            title: _notifications[i].title,
            message: _notifications[i].message,
            type: _notifications[i].type,
            referenceType: _notifications[i].referenceType,
            referenceId: _notifications[i].referenceId,
            isRead: true,
            createdAt: _notifications[i].createdAt,
            readAt: DateTime.now(),
          );
        }
      }
      
      _count = NotificationCount(total: _count.total, unread: 0);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _apiService.deleteNotification(id);
      
      final notification = _notifications.firstWhere((n) => n.id == id);
      _notifications.removeWhere((n) => n.id == id);
      
      _count = NotificationCount(
        total: _count.total - 1,
        unread: notification.isRead ? _count.unread : _count.unread - 1,
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      // Delete all notifications one by one since bulk delete API not available
      final ids = _notifications.map((n) => n.id).toList();
      for (final id in ids) {
        await _apiService.deleteNotification(id);
      }
      _notifications = [];
      _count = NotificationCount(total: 0, unread: 0);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
