import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_notification_model.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../widgets/classical_dialog.dart'; // 确保导入了您的 ClassicalDialog

class NotificationsScreen extends StatefulWidget {
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
    final user = Provider.of<AppProvider>(context, listen: false).currentUser;

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

  // --- 核心操作：显示 ClassicalDialog ---
  void _showNotificationDetail(BuildContext context, UserNotificationModel notification) {
    // 打开详情时自动标记为已读
    if (!notification.isRead) {
      FirestoreService.markNotificationAsRead(notification.id);
    }

    showDialog(
      context: context,
      builder: (context) => ClassicalDialog(
        title: notification.title,
        content: notification.message,
        confirmText: 'CLOSE', // 按钮文字
        onConfirm: () => Navigator.pop(context),
        // 关键修改：不传 cancelText 和 onCancel，ClassicalDialog 会自动显示单按钮模式
      ),
    );
  }

  // --- 顶部清除所有未读的确认弹窗 ---
  void _showMarkAllReadDialog(List<UserNotificationModel> unreadNotifications) {
    final userId = _currentUserId;
    if (userId == null) return;

    // 检查是否有未读通知
    if (unreadNotifications.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => ClassicalDialog(
          title: 'No unread notifications',
          content: 'All your notifications are already read.',
          confirmText: 'OK',
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return;
    }

    // 这个操作仍然需要确认，所以保留 cancelText
    showDialog(
      context: context,
      builder: (context) => ClassicalDialog(
        title: 'Mark all as read?',
        content: 'This will move all unread notifications to history.',
        confirmText: 'CONFIRM',
        cancelText: 'CANCEL',
        onConfirm: () {
          Navigator.pop(context);
          FirestoreService.markAllNotificationsAsRead(userId);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // 如果没有用户登录，显示 loading 或空
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<List<UserNotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9F9F9),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F9F9),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final allNotifications = snapshot.data ?? [];
        final unread = allNotifications.where((n) => !n.isRead).toList();
        final history = allNotifications.where((n) => n.isRead).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            title: const Text(
              'Notifications',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.black87),
                tooltip: 'Mark all as read',
                onPressed: () => _showMarkAllReadDialog(unread),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4F46E5),
              tabs: const [
                Tab(text: 'Unread'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(unread, isEmptyMessage: 'No new notifications'),
              _buildNotificationList(history, isEmptyMessage: 'No history'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationList(List<UserNotificationModel> list, {required String isEmptyMessage}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(isEmptyMessage, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = list[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(UserNotificationModel notification) {
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // 点击整个卡片弹出 ClassicalDialog
          onTap: () => _showNotificationDetail(context, notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标区域
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                // 内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(notification.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 辅助方法 ---

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
}