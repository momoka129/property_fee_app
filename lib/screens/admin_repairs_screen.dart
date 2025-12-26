import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/repair_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';

class AdminRepairsScreen extends StatefulWidget {
  const AdminRepairsScreen({super.key});

  @override
  State<AdminRepairsScreen> createState() => _AdminRepairsScreenState();
}

class _AdminRepairsScreenState extends State<AdminRepairsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryColor = const Color(0xFF4F46E5);
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================= 1. 玻璃拟态分配弹窗 =================
  void _showAssignDialog(BuildContext context, RepairModel repair) {
    String? selectedWorkerId;
    DateTime? selectedDate;
    bool isLoading = false;

    // 限制日期：从明天开始
    final DateTime firstDate = repair.createdAt.add(const Duration(days: 1));
    final DateTime lastDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return StreamBuilder<List<UserModel>>(
              stream: FirestoreService.getWorkersStream(),
              builder: (context, snapshot) {
                final workers = snapshot.data ?? [];

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(20),
                  child: GlassContainer(
                    opacity: 0.95,
                    blur: 20,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.handyman_rounded, color: Colors.orange, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Text('Assign Worker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text("Select Worker", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 8),
                        if (workers.isEmpty)
                          const Text("No workers found. Add in Users tab.", style: TextStyle(color: Colors.red))
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedWorkerId,
                                hint: const Text("Choose a worker..."),
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down_rounded, color: primaryColor),
                                items: workers.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                                onChanged: (val) => setStateDialog(() => selectedWorkerId = val),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        const Text("Select Date", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? firstDate,
                              firstDate: firstDate,
                              lastDate: lastDate,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(primary: primaryColor),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setStateDialog(() => selectedDate = picked);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 18, color: primaryColor),
                                const SizedBox(width: 12),
                                Text(
                                  selectedDate == null
                                      ? "Choose date"
                                      : DateFormat('yyyy-MM-dd (EEEE)').format(selectedDate!),
                                  style: TextStyle(
                                      color: selectedDate == null ? Colors.grey : Colors.black87,
                                      fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w600
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
                            ),
                            const SizedBox(width: 8),
                            isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: () async {
                                if (selectedWorkerId == null || selectedDate == null) return;

                                setStateDialog(() => isLoading = true);
                                try {
                                  final worker = workers.firstWhere((w) => w.id == selectedWorkerId);
                                  await FirestoreService.assignRepair(
                                    repairId: repair.id,
                                    userId: repair.userId,
                                    workerId: worker.id,
                                    workerName: worker.name,
                                    repairDate: selectedDate!,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Assigned successfully!"), backgroundColor: Colors.green)
                                    );
                                  }
                                } catch (e) {
                                  setStateDialog(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                }
                              },
                              child: const Text("Assign & Start"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= 2. 拒绝弹窗 =================
  void _showRejectDialog(BuildContext context, RepairModel repair) {
    final reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            opacity: 0.95,
            blur: 20,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reject Request", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                const Text("Reason for rejection:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.6),
                    hintText: "Enter reason...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 8),
                    isLoading
                        ? const CircularProgressIndicator()
                        : FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (reasonController.text.isEmpty) return;
                        setStateDialog(() => isLoading = true);
                        try {
                          await FirestoreService.rejectRepair(
                              repairId: repair.id,
                              userId: repair.userId,
                              reason: reasonController.text.trim()
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Rejected")));
                          }
                        } catch (e) {
                          setStateDialog(() => isLoading = false);
                        }
                      },
                      child: const Text("Reject"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= 3. 主页面 (修复Header) =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== 修复后的 Header =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    // 1. 返回按钮 (带玻璃背景)
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8), // 半透明白色背景
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 2. 标题
                    const Text(
                        'Repair Requests',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
                    // 3. 右侧留空 (移除了无用的图标)
                  ],
                ),
              ),

              // TabBar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(4),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'History'),
                  ],
                ),
              ),

              // 内容区域
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRepairList('pending'),
                    _buildRepairList('in_progress'),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepairList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('repairs')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text("No $status requests", style: TextStyle(color: Colors.grey.withOpacity(0.5))),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final repair = RepairModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return _buildGlassCard(repair, isHistory: false);
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('repairs')
          .where('status', whereIn: ['completed', 'rejected'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Text("No history", style: TextStyle(color: Colors.grey.withOpacity(0.5))));

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final repair = RepairModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return _buildGlassCard(repair, isHistory: true);
          },
        );
      },
    );
  }

  Widget _buildGlassCard(RepairModel repair, {required bool isHistory}) {
    return GlassContainer(
      opacity: 0.8,
      blur: 15,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repair.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(repair.location, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(repair.status),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              repair.description,
              style: TextStyle(color: Colors.grey[800], height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, HH:mm').format(repair.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            if (repair.workerName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.engineering_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Worker: ${repair.workerName}",
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (repair.repairDate != null) ...[
                      const Spacer(),
                      Text(
                        DateFormat('MM/dd').format(repair.repairDate!),
                        style: TextStyle(color: primaryColor, fontSize: 13),
                      ),
                    ]
                  ],
                ),
              ),
            ],

            if (repair.status == 'rejected' && repair.rejectionReason != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Text("Reason: ${repair.rejectionReason}", style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            if (repair.status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(context, repair),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _showAssignDialog(context, repair),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("Assign"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        label = 'Pending';
        break;
      case 'in_progress':
        color = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        label = 'In Progress';
        break;
      case 'completed':
        color = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        label = 'Completed';
        break;
      case 'rejected':
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        label = 'Rejected';
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.shade100;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}