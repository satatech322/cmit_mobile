import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/models/notification_model.dart';
import 'package:cmit/services/notification_storage.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final raw = await NotificationStorage.getAllNotifications();
    final notifications = raw
        .map((e) => NotificationModel.fromJson(e))
        .toList();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int index) async {
    await NotificationStorage.markAsRead(index);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await NotificationStorage.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    await NotificationStorage.clearAll();
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              onPressed: _markAllAsRead,
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationTile(notification, index);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification, int index) {
    return ListTile(
      onTap: () => _markAsRead(index),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.grey.shade100
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getNotificationIcon(notification.type),
          color: notification.isRead
              ? Colors.grey.shade400
              : AppTheme.primaryColor,
          size: 22,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'assessment':
        return Icons.assignment_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'alert':
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
