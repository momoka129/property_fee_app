import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/data_migration_service.dart';

class AdminBillsScreen extends StatefulWidget {
  const AdminBillsScreen({super.key});

  @override
  State<AdminBillsScreen> createState() => _AdminBillsScreenState();
}

class _AdminBillsScreenState extends State<AdminBillsScreen> {
  // 统一样式变量
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);
  final Color primaryColor = const Color(0xFF4F46E5);
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
                child: _buildBillList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. 自定义顶部栏 ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                'Bills Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // 更多操作 (例如数据迁移)
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: kCardShadow,
                  ),
                  child: const Icon(Icons.more_horiz, color: Colors.black87),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'migrate') {
                    _showUserMigrationDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'migrate',
                    child: Row(
                      children: [
                        Icon(Icons.move_up, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Migrate Data'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // 添加按钮
              InkWell(
                onTap: () => _showEditDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. 账单列表区域 ---
  Widget _buildBillList() {
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getAllBillsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final bills = snapshot.data ?? [];
        if (bills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No bills record found', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        // 获取用户信息以匹配名称
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
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bill = bills[index];
                final linkedUser = userById[bill.userId];
                return _buildBillCard(bill, linkedUser);
              },
            );
          },
        );
      },
    );
  }

  // --- 3. 单个账单卡片 ---
  Widget _buildBillCard(BillModel bill, UserModel? user) {
    final displayName = user?.name ?? bill.payerName;
    final isPaid = bill.status.toLowerCase() == 'paid';
    final isOverdue = bill.status.toLowerCase() == 'overdue';

    // 状态颜色
    Color statusColor = Colors.grey;
    String statusText = bill.status.toUpperCase();
    if (isPaid) {
      statusColor = const Color(0xFF10B981); // Green
    } else if (isOverdue) {
      statusColor = const Color(0xFFEF4444); // Red
    } else {
      statusColor = const Color(0xFFF59E0B); // Amber
    }

    // 类别图标
    IconData categoryIcon = Icons.receipt;
    Color iconBgColor = Colors.blue.withOpacity(0.1);
    Color iconColor = Colors.blue;

    switch (bill.category.toLowerCase()) {
      case 'water':
        categoryIcon = Icons.water_drop;
        iconBgColor = Colors.lightBlue.withOpacity(0.1);
        iconColor = Colors.lightBlue;
        break;
      case 'electricity':
        categoryIcon = Icons.flash_on;
        iconBgColor = Colors.amber.withOpacity(0.1);
        iconColor = Colors.amber[700]!;
        break;
      case 'internet':
        categoryIcon = Icons.wifi;
        iconBgColor = Colors.purple.withOpacity(0.1);
        iconColor = Colors.purple;
        break;
      case 'maintenance':
        categoryIcon = Icons.build_circle;
        iconBgColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        break;
      case 'parking':
        categoryIcon = Icons.local_parking;
        iconBgColor = Colors.indigo.withOpacity(0.1);
        iconColor = Colors.indigo;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: kCardRadius,
        boxShadow: kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: kCardRadius,
          onTap: () {
            // 点击卡片直接弹出编辑/删除菜单，或者你可以选择跳转详情
            _showCardActionMenu(bill);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(categoryIcon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                // 中间信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(bill.dueDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                // 右侧金额和状态
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${bill.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.black87 : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  void _showCardActionMenu(BillModel bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('Edit Bill'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, bill: bill);
              },
            ),
            const Divider(indent: 20, endIndent: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              title: const Text('Delete Bill'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(bill);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to delete this bill? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirestoreService.deleteBill(bill.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  // --- 逻辑方法保持不变，仅微调 UI ---

  Future<void> _showUserMigrationDialog(BuildContext context) async {
    UserModel? selectedUser;
    bool isLoading = false;
    final users = await FirestoreService.getAllUsers();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Migrate User Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select a primary user. This will move ALL bills to this user ID.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserModel>(
                  value: selectedUser,
                  decoration: InputDecoration(
                    labelText: 'Select Target User',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: users.map((UserModel user) {
                    return DropdownMenuItem<UserModel>(
                      value: user,
                      child: Text(user.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (UserModel? newValue) {
                    setState(() {
                      selectedUser = newValue;
                    });
                  },
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Migrating...', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading || selectedUser == null
                  ? null
                  : () async {
                setState(() => isLoading = true);
                try {
                  await DataMigrationService.migrateAllDataToSelectedUser(selectedUser!.id);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Success! Data migrated to ${selectedUser!.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {}); // Refresh
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                  }
                } finally {
                  if (mounted) {
                    setState(() => isLoading = false);
                  }
                }
              },
              child: const Text('Start Migration'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, {BillModel? bill}) async {
    final titleCtrl = TextEditingController(text: bill?.title ?? '');
    final amountCtrl = TextEditingController(text: bill != null ? bill.amount.toString() : '');
    String selectedCategory = bill?.category ?? 'maintenance';
    UserModel? selectedUser;
    final addressCtrl = TextEditingController(text: bill?.propertySimpleAddress ?? '');
    DateTime dueDate = bill?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    DateTime billingDate = bill?.billingDate ?? DateTime.now();

    final users = await FirestoreService.getUsers();

    if (bill != null && bill.userId.isNotEmpty) {
      try {
        selectedUser = users.firstWhere((user) => user.id == bill.userId);
      } catch (e) {
        // user not found
      }
    }

    final List<String> categories = [
      'maintenance', 'water', 'electricity', 'gas', 'parking', 'management', 'internet'
    ];

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(bill == null ? 'New Bill' : 'Edit Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(titleCtrl, 'Title'),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserModel>(
                  value: selectedUser,
                  decoration: InputDecoration(
                    labelText: 'Payer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: users.map((UserModel user) {
                    return DropdownMenuItem<UserModel>(
                      value: user,
                      child: Text(user.name),
                    );
                  }).toList(),
                  onChanged: (UserModel? newValue) {
                    setState(() {
                      selectedUser = newValue;
                      if (newValue != null) {
                        addressCtrl.text = newValue.propertySimpleAddress;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(addressCtrl, 'Address'),
                const SizedBox(height: 12),
                _buildDialogTextField(amountCtrl, 'Amount (RM)', isNumber: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) => setState(() => selectedCategory = newValue!),
                ),
                const SizedBox(height: 16),
                _buildDatePickerRow('Due Date', dueDate, (date) => setState(() => dueDate = date)),
                _buildDatePickerRow('Billing Date', billingDate, (date) => setState(() => billingDate = date)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: primaryColor,
              ),
              onPressed: () async {
                final payload = {
                  'userId': selectedUser?.id ?? bill?.userId ?? '',
                  'payerName': selectedUser?.name ?? '',
                  'propertySimpleAddress': addressCtrl.text,
                  'title': titleCtrl.text,
                  'description': '',
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'dueDate': dueDate,
                  'billingDate': billingDate,
                  'status': bill?.status ?? 'unpaid',
                  'category': selectedCategory,
                  'paymentId': bill?.paymentId,
                };

                try {
                  if (bill == null) {
                    await FirestoreService.createBill(payload);
                  } else {
                    await FirestoreService.updateBill(bill.id, payload);
                  }
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime date, Function(DateTime) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          TextButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(DateFormat('yyyy-MM-dd').format(date)),
            onPressed: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100)
              );
              if (picked != null) onSelect(picked);
            },
          ),
        ],
      ),
    );
  }
}