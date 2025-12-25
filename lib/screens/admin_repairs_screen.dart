import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/repair_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AdminRepairsScreen extends StatefulWidget {
  const AdminRepairsScreen({super.key});

  @override
  State<AdminRepairsScreen> createState() => _AdminRepairsScreenState();
}

class _AdminRepairsScreenState extends State<AdminRepairsScreen> {
  // 统一 UI 风格变量
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);
  final Color cardColor = Colors.white;
  final BorderRadius kCardRadius = BorderRadius.circular(20);
  final List<BoxShadow> kCardShadow = [
    BoxShadow(
      color: const Color(0xFF1F2937).withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  Future<void> _updateRepairStatus(String repairId, String newStatus) async {
    try {
      DateTime? completedAt;
      if (newStatus == 'completed') {
        completedAt = DateTime.now();
      }
      await FirestoreService.updateRepairStatus(repairId, newStatus, completedAt: completedAt);
      if (mounted) {
        Navigator.pop(context); // 关闭底部菜单
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildRepairsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. 顶部 Header ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: kCardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Maintenance Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. 列表构建 ---
  Widget _buildRepairsList() {
    return StreamBuilder<List<RepairModel>>(
      stream: FirestoreService.getAllRepairsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final repairs = snapshot.data ?? [];
        if (repairs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No maintenance requests', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        // 获取用户信息
        return FutureBuilder<List<UserModel>>(
          future: FirestoreService.getUsers(),
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? [];
            final Map<String, UserModel> userById = {
              for (var u in users) u.id: u
            };

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: repairs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final repair = repairs[index];
                final linkedUser = userById[repair.userId];
                return _buildRepairCard(repair, linkedUser);
              },
            );
          },
        );
      },
    );
  }

  // --- 3. 卡片组件 ---
  Widget _buildRepairCard(RepairModel repair, UserModel? user) {
    final displayName = user?.name ?? 'Unknown User';
    final displayAddress = user?.propertySimpleAddress ?? 'Unknown Unit';

    // 状态样式逻辑
    Color statusColor;
    String statusText = repair.statusDisplay;
    IconData statusIcon;

    switch (repair.status) {
      case 'completed':
        statusColor = const Color(0xFF10B981); // Green
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = const Color(0xFF3B82F6); // Blue
        statusIcon = Icons.pending_actions;
        break;
      default:
        statusColor = const Color(0xFFF59E0B); // Amber
        statusIcon = Icons.schedule;
    }

    // 优先级颜色逻辑 (左侧条)
    Color priorityColor;
    String priorityText = repair.priorityDisplay.toUpperCase();
    switch (repair.priority.toLowerCase()) {
      case 'high':
        priorityColor = const Color(0xFFEF4444); // Red
        break;
      case 'medium':
        priorityColor = const Color(0xFFF97316); // Orange
        break;
      default:
        priorityColor = const Color(0xFF10B981); // Green
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: kCardRadius,
        boxShadow: kCardShadow,
      ),
      child: ClipRRect(
        borderRadius: kCardRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧优先级指示条
              Container(
                width: 6,
                color: priorityColor,
              ),
              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              repair.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // 优先级标签
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priorityText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 用户信息
                      _buildInfoRow(Icons.person_outline, "$displayName • $displayAddress"),
                      const SizedBox(height: 6),

                      // 位置信息
                      _buildInfoRow(Icons.location_on_outlined, repair.location),
                      const SizedBox(height: 6),

                      // 时间信息
                      _buildInfoRow(
                          Icons.calendar_today_outlined,
                          "Created: ${DateFormat('MMM dd, yyyy').format(repair.createdAt)}"
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // 底部：状态 + 操作按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 状态胶囊
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 操作按钮
                          InkWell(
                            onTap: () => _showStatusUpdateSheet(context, repair),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                "Update Status",
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- 4. 底部状态更新菜单 ---
  void _showStatusUpdateSheet(BuildContext context, RepairModel repair) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Update Request Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildStatusOption(
              context,
              title: "Pending",
              icon: Icons.schedule,
              color: Colors.orange,
              isSelected: repair.status == 'pending',
              onTap: () => _updateRepairStatus(repair.id, 'pending'),
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              title: "In Progress",
              icon: Icons.pending_actions,
              color: Colors.blue,
              isSelected: repair.status == 'in_progress',
              onTap: () => _updateRepairStatus(repair.id, 'in_progress'),
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              title: "Completed",
              icon: Icons.check_circle_outline,
              color: Colors.green,
              isSelected: repair.status == 'completed',
              onTap: () => _updateRepairStatus(repair.id, 'completed'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)
                  ]
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check, color: color),
          ],
        ),
      ),
    );
  }
}