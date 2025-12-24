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

  Future<void> _showUserMigrationDialog(BuildContext context) async {
    UserModel? selectedUser;
    bool isLoading = false;

    // Get all users
    final users = await FirestoreService.getAllUsers();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('用户数据迁移'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择要作为主要用户的账户。这将把所有账单和用户ID更新为此用户的ID和姓名。\n\n警告：此操作不可逆！',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserModel>(
                  value: selectedUser,
                  decoration: const InputDecoration(
                    labelText: '选择用户',
                    border: OutlineInputBorder(),
                  ),
                  items: users.map((UserModel user) {
                    return DropdownMenuItem<UserModel>(
                      value: user,
                      child: Text('${user.name} (${user.email}) - ${user.role}'),
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
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('正在迁移数据，请稍候...'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
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
                            content: Text('数据迁移成功！所有数据已更新到用户：${selectedUser!.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Refresh the screen
                        setState(() {});
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('迁移失败：$e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => isLoading = false);
                      }
                    }
                  },
              child: const Text('开始迁移'),
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

    // Get users list
    final users = await FirestoreService.getUsers();

    // If editing existing bill, find the corresponding user
    if (bill != null && bill.userId.isNotEmpty) {
      try {
        selectedUser = users.firstWhere((user) => user.id == bill.userId);
      } catch (e) {
        // User not found, selectedUser remains null
      }
    }

    final List<String> categories = [
      'maintenance',
      'water',
      'electricity',
      'gas',
      'parking',
      'management'
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(bill == null ? 'Create Bill' : 'Edit Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                DropdownButtonFormField<UserModel>(
                  value: selectedUser,
                  decoration: const InputDecoration(labelText: 'Payer Name'),
                  items: users.map((UserModel user) {
                    return DropdownMenuItem<UserModel>(
                      value: user,
                      child: Text(user.name),
                    );
                  }).toList(),
                  onChanged: (UserModel? newValue) {
                    setState(() {
                      selectedUser = newValue;
                      // Auto-fill property address and unit when user is selected
                      if (newValue != null) {
                        addressCtrl.text = newValue.propertySimpleAddress;
                      }
                    });
                  },
                ),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Property Address')),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Due: ${DateFormat('yyyy-MM-dd').format(dueDate)}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) dueDate = picked;
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Billing: ${DateFormat('yyyy-MM-dd').format(billingDate)}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: billingDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) billingDate = picked;
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<BillModel>>(
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
            return const Center(child: Text('No bills'));
          }
          return FutureBuilder<List<UserModel>>(
            future: FirestoreService.getUsers(),
            builder: (context, usersSnapshot) {
              final users = usersSnapshot.data ?? [];
              final Map<String, UserModel> userById = {
                for (var u in users) u.id: u
              };

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final linkedUser = userById[bill.userId];
                  final displayName = linkedUser?.name ?? bill.payerName;

                  return Card(
                    child: ListTile(
                      title: Text(bill.title),
                      subtitle: Text('RM ${bill.amount.toStringAsFixed(2)} • $displayName'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _showEditDialog(context, bill: bill);
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Delete Bill'),
                                content: const Text('Are you sure you want to delete this bill?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              try {
                                await FirestoreService.deleteBill(bill.id);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}