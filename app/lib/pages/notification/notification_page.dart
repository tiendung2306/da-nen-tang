import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_boilerplate/providers/notification_provider.dart';
import 'package:flutter_boilerplate/models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    provider.refresh();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: !provider.showUnreadOnly,
                      onSelected: (_) => provider.setShowUnreadOnly(false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Chưa đọc (${provider.unreadCount})'),
                      selected: provider.showUnreadOnly,
                      onSelected: (_) => provider.setShowUnreadOnly(true),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!notification.isRead)
              ListTile(
                leading: const Icon(
                  Icons.mark_email_read,
                  color: Color(0xFFF26F21),
                ),
                title: const Text('Đánh dấu đã đọc'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<NotificationProvider>().markAsRead([notification.id]);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa thông báo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteNotification(notification);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
    if (provider.notifications.isEmpty) {
      return Center(
        child: Text(provider.showUnreadOnly ? 'Không có thông báo chưa đọc' : 'Không có thông báo nào'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.notifications.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final notification = provider.notifications[index];
          return NotificationListItem(notification: notification);
        },
      ),
    );
  }
}

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  const NotificationListItem({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: Text(notification.message),
      subtitle: Text(timeago.format(DateTime.parse(notification.createdAt), locale: 'vi')),
      trailing: notification.read ? null : const Icon(Icons.circle, color: Colors.blue, size: 12),
      onTap: () {
        if (!notification.read) {
          context.read<NotificationProvider>().markAsRead([notification.id.toString()]);
        }
      },
    );
  }
}
