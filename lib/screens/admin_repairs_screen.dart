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

  @override
  void initState() {
    super.initState();
    // 检查是否有超时需要取消的订单（维修请求）
    FirestoreService.checkAutoCancelRepairs();
  }

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

  Future<void> _forceCompleteRepair(RepairModel repair) async {
    try {
      await FirestoreService.updateRepairStatus(
        repair.id,
        'completed',
        completedAt: DateTime.now(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as completed'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
      );
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
            final Map<String, UserModel> userById = {for (var u in users) u.id: u};

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

    // ====== 工人/时间信息展示（按你的 RepairModel 字段实际情况调整命名）======
    // 常见字段命名示例：assignedWorkerName / scheduledDate / completedAt
    final String? workerName = (repair as dynamic).assignedWorkerName as String?;
    final DateTime? scheduledDate = (repair as dynamic).scheduledDate as DateTime?;
    final DateTime? completedAt = (repair as dynamic).completedAt as DateTime?;
    // =============================================================

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
                        "Created: ${DateFormat('MMM dd, yyyy').format(repair.createdAt)}",
                      ),

                      // 工人 + 预约日期（若有）
                      if (workerName != null && workerName.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(Icons.engineering_outlined, "Worker: $workerName"),
                      ],
                      if (scheduledDate != null) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(Icons.event_outlined, "Scheduled: ${DateFormat('yyyy-MM-dd').format(scheduledDate)}"),
                      ],
                      if (completedAt != null) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow(Icons.check_circle_outline, "Completed: ${DateFormat('yyyy-MM-dd').format(completedAt)}"),
                      ],

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
                                "Manage",
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

  // --- 4. 底部状态更新菜单（按你给的指示重写） ---
  void _showStatusUpdateSheet(BuildContext context, RepairModel repair) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许弹窗变高
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Manage Request", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // 1) Pending：分配 + 拒绝
              if (repair.status == 'pending') ...[
                _buildStatusOption(
                  context,
                  title: "Assign Worker & Start",
                  icon: Icons.engineering,
                  color: Colors.blue,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showAssignDialog(context, repair);
                  },
                ),
                const SizedBox(height: 12),
                _buildStatusOption(
                  context,
                  title: "Reject Request",
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showRejectDialog(context, repair);
                  },
                ),
              ]
              // 2) In Progress：管理员可强制完成
              else if (repair.status == 'in_progress') ...[
                _buildStatusOption(
                  context,
                  title: "Mark as Completed",
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  isSelected: false,
                  onTap: () => _forceCompleteRepair(repair),
                ),
              ] else ...[
                const Text("No actions available for this status."),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 新增：分配工人弹窗
  void _showAssignDialog(BuildContext context, RepairModel repair) async {
    List<dynamic> workers = [];
    try {
      final result = await FirestoreService.getWorkers(); // 获取工人列表
      workers = result as List<dynamic>;
    } catch (_) {
      // 不阻断 UI：允许走手动输入
      workers = [];
    }

    DateTime? selectedDate;
    String? selectedWorkerName;

    // 默认最小日期为创建日期 + 1 天
    final firstDate = repair.createdAt.add(const Duration(days: 1));
    final today = DateTime.now();
    final initialDate = today.isAfter(firstDate) ? today : firstDate;

    if (!context.mounted) return;

    // 尽量兼容：workers 可能是 String 列表，也可能是对象列表（带 name 字段）
    final workerNames = workers
        .map<String>((w) {
      if (w is String) return w;
      final dynamic dw = w;
      final name = dw.name?.toString();
      return name ?? '';
    })
        .where((n) => n.trim().isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Assign Worker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 选择日期
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Select Date (Required)'
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                  leading: const Icon(Icons.calendar_today),
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: firstDate, // 必须从第二天开始
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 选择或输入工人
                if (workerNames.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Worker',
                      border: OutlineInputBorder(),
                    ),
                    items: workerNames
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (val) => selectedWorkerName = val,
                  )
                else
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Worker Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => selectedWorkerName = val,
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = selectedWorkerName?.trim() ?? '';
                  if (selectedDate != null && name.isNotEmpty) {
                    try {
                      await FirestoreService.assignRepair(
                        repair.id,
                        repair.userId,
                        name,
                        selectedDate!,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Assigned successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Assign failed: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Assign & Start'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 新增：拒绝理由弹窗
  void _showRejectDialog(BuildContext context, RepairModel repair) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why is this rejected?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;

              try {
                await FirestoreService.rejectRepair(repair.id, repair.userId, reason);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rejected successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reject failed: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // _buildStatusOption 保持不变
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
                  if (!isSelected) BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
                ],
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
            if (isSelected) Icon(Icons.check, color: color),
          ],
        ),
      ),
    );
  }
}
