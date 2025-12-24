import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_notification_model.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import 'bill_detail.dart';
import 'announcement_detail_screen.dart'; // 假设你有这个，没有也没关系

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppProvider>(context).currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Unread'),
              Tab(text: 'History'),
            ],
          ),
          actions: [
            // 只有用户想一键清空时才用这个
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () => _showMarkAllReadDialog(context, user.id),
            ),
          ],
        ),
        body: StreamBuilder<List<UserNotificationModel>>(
          stream: FirestoreService.getUserNotificationsStream(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allNotifications = snapshot.data ?? [];

            // 分类：未读 vs 已读
            final unreadList = allNotifications.where((n) => !n.isRead).toList();
            final readList = allNotifications.where((n) => n.isRead).toList();

            return TabBarView(
              children: [
                _buildNotificationList(context, unreadList, isUnreadTab: true),
                _buildNotificationList(context, readList, isUnreadTab: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, List<UserNotificationModel> notifications, {required bool isUnreadTab}) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnreadTab ? Icons.notifications_none : Icons.history,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isUnreadTab ? 'No new notifications' : 'No history',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Dismissible(
          key: Key(notification.id),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            FirestoreService.deleteNotification(notification.id);
          },
          child: Card(
            elevation: isUnreadTab ? 2 : 0,
            color: isUnreadTab ? Colors.white : Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isUnreadTab ? _getColorForType(notification.type).withOpacity(0.1) : Colors.grey[200],
                child: Icon(
                  _getIconForType(notification.type),
                  color: isUnreadTab ? _getColorForType(notification.type) : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnreadTab ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isUnreadTab ? Colors.black87 : Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(notification.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              onTap: () {
                // 【重点】这里绝对不要调用 markAsRead
                // 只打开弹窗
                _showDetailDialog(context, notification);
              },
            ),
          ),
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, UserNotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getIconForType(notification.type), color: _getColorForType(notification.type)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(notification.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          // 按钮 1：仅仅关闭（不标记已读）
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),

          // 按钮 2：如果有跳转链接，显示跳转按钮 (不自动标记已读，看用户选择)
          if (notification.relatedId != null && notification.type != 'general')
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(_getActionLabel(notification.type)),
              onPressed: () {
                Navigator.pop(context); // 关弹窗
                _handleNavigation(context, notification); // 跳转
              },
            ),

          // 按钮 3：【核心】标记为已读并归档
          // 只有点这个，它才会消失（移动到History）
          if (!notification.isRead)
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Mark as Read'),
              onPressed: () {
                FirestoreService.markNotificationAsRead(notification.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, UserNotificationModel notification) async {
    if ((notification.type == 'bill_overdue' || notification.type == 'bill_created') &&
        notification.relatedId != null) {
      try {
        final bill = await FirestoreService.getBillById(notification.relatedId!);
        if (context.mounted && bill != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BillDetailScreen(bill: bill)),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill not found')));
        }
      } catch (e) {
        // error
      }
    }
  }

  void _showMarkAllReadDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark all as read?'),
        content: const Text('This will move all unread notifications to history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              FirestoreService.markAllNotificationsAsRead(userId);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'bill_overdue': return Icons.warning_amber_rounded;
      case 'bill_created': return Icons.receipt_long;
      case 'package': return Icons.inventory_2_outlined;
      case 'announcement': return Icons.campaign;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'bill_overdue': return Colors.red;
      case 'bill_created': return Colors.blue;
      case 'package': return Colors.orange;
      case 'announcement': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getActionLabel(String type) {
    switch (type) {
      case 'bill_overdue': return 'Pay Now';
      case 'bill_created': return 'View Bill';
      case 'package': return 'View Package';
      default: return 'View';
    }
  }
}