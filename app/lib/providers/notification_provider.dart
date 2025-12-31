import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/notification_model.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = locator<ApiService>();

  List<AppNotification> _notifications = [];
  NotificationCount _count = NotificationCount(total: 0, unread: 0);
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _showUnreadOnly = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  NotificationCount get count => _count;
  int get unreadCount => _count.unread;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get showUnreadOnly => _showUnreadOnly;
  String? get error => _error;

  void setShowUnreadOnly(bool value) {
    if (_showUnreadOnly != value) {
      _showUnreadOnly = value;
      refresh();
    }
  }

  Future<void> refresh() async {
    await fetchNotifications(isRefresh: true);
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _notifications = [];
      _hasMore = true;
    }
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getNotifications(page: _currentPage, unreadOnly: _showUnreadOnly);
      _notifications.addAll(result.content);
      _hasMore = !result.last;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCount() async {
    try {
      _count = await _apiService.getNotificationCount();
      notifyListeners();
    } catch (e) {
      // silent fail is acceptable for count
    }
  }

  Future<void> markAsRead(List<String> ids) async {
    await _apiService.markNotificationsAsRead(ids);
    _notifications.where((n) => ids.contains(n.id.toString())).forEach((n) {
      final index = _notifications.indexOf(n);
      _notifications[index] = n.copyWith(read: true);
    });
    fetchCount();
    notifyListeners();
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
    await _apiService.markAllNotificationsAsRead();
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    fetchCount();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _apiService.deleteNotification(id);
    _notifications.removeWhere((n) => n.id.toString() == id);
    fetchCount();
    notifyListeners();
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
