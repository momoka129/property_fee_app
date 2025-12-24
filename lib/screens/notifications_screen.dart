import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_notification_model.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import 'bill_detail.dart';

class NotificationsScreen extends StatefulWidget { // 改为 StatefulWidget
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late Stream<List<UserNotificationModel>> _notificationsStream;
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取当前用户ID
    final user = Provider.of<AppProvider>(context, listen: false).currentUser;

    // 只有当用户ID发生变化（或首次初始化）时，才重新创建 Stream
    // 这解决了“一闪而过”的问题
    if (user != null && user.id != _currentUserId) {
      _currentUserId = user.id;
      _notificationsStream = FirestoreService.getUserNotificationsStream(user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppProvider>(context).currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unread'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => _showMarkAllReadDialog(context, user.id),
          ),
        ],
      ),
      // 使用初始化好的 _notificationsStream，而不是每次 build 都创建新的
      body: StreamBuilder<List<UserNotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          // 调试信息：如果出错，打印错误
          if (snapshot.hasError) {
            print("Stream Error: ${snapshot.error}");
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allNotifications = snapshot.data ?? [];

          // 确保 isRead 判断准确
          final unreadList = allNotifications.where((n) => n.isRead == false).toList();
          final readList = allNotifications.where((n) => n.isRead == true).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(context, unreadList, isUnreadTab: true),
              _buildNotificationList(context, readList, isUnreadTab: false),
            ],
          );
        },
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
              onTap: () => _showDetailDialog(context, notification),
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
              Text(notification.message, style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          if (notification.relatedId != null && notification.type != 'general')
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(_getActionLabel(notification.type)),
              onPressed: () {
                Navigator.pop(context);
                _handleNavigation(context, notification);
              },
            ),
          // 标记已读按钮
          if (!notification.isRead)
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Mark as Read'),
              onPressed: () async {
                // 1. 先关闭弹窗，避免等待
                Navigator.pop(context);
                // 2. 更新数据库
                await FirestoreService.markNotificationAsRead(notification.id);
                // 3. 因为是 Stream，UI 会自动刷新并将该条目移到 History
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
        }
      } catch (e) {
        print("Navigation error: $e");
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
              Navigator.pop(context);
              FirestoreService.markAllNotificationsAsRead(userId);
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