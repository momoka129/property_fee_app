import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';

class AdminBillsScreen extends StatefulWidget {
  const AdminBillsScreen({super.key});

  @override
  State<AdminBillsScreen> createState() => _AdminBillsScreenState();
}

class _AdminBillsScreenState extends State<AdminBillsScreen> {
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

  // 账单过滤状态
  String _selectedFilter = 'all'; // 'all', 'paid', 'unpaid'

  // 选择状态管理（仅在unpaid过滤器下使用）
  bool _isSelectionMode = false;
  final Set<String> _selectedBillIds = {};

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
              _buildFilterButtons(),
              if (_selectedFilter == 'unpaid') _buildSelectionActions(),
              Expanded(child: _buildBillList()),
            ],
          ),
        ),
      ),
    );
  }

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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: kCardShadow),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Bills Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: () => _showEditDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text('Filter:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: kCardShadow,
              ),
              child: ToggleButtons(
                isSelected: [_selectedFilter == 'all', _selectedFilter == 'paid', _selectedFilter == 'unpaid'],
                onPressed: (index) {
                  final newFilter = ['all', 'paid', 'unpaid'][index];
                  setState(() {
                    _selectedFilter = newFilter;
                    // 切换过滤器时重置选择状态
                    _isSelectionMode = false;
                    _selectedBillIds.clear();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: primaryColor,
                color: Colors.black87,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 70),
                children: const [
                  Text('All'),
                  Text('Paid'),
                  Text('Unpaid'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions() {
    // Use Wrap so buttons can wrap to the next line on narrow screens and avoid RenderFlex overflow.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LayoutBuilder(builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            if (_isSelectionMode) ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
                child: TextButton.icon(
                  onPressed: _selectedBillIds.isEmpty ? null : _confirmBulkDelete,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: Text('Delete Selected (${_selectedBillIds.length})',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.28),
                child: TextButton.icon(
                  onPressed: _toggleSelectAll,
                  icon: Icon(_isAllSelected ? Icons.deselect : Icons.select_all, color: primaryColor),
                  label: Text(_isAllSelected ? 'Deselect All' : 'Select All',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) {
                      _selectedBillIds.clear();
                    }
                  });
                },
                icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist, color: primaryColor),
                label: Text(_isSelectionMode ? 'Cancel' : 'Select',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBillList() {
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getAllBillsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

        // 应用过滤
        List<BillModel> bills = snapshot.data ?? [];
        if (_selectedFilter == 'paid') {
          bills = bills.where((bill) => bill.status.toLowerCase() == 'paid').toList();
          _currentUnpaidBills = []; // 清空未支付账单列表
        } else if (_selectedFilter == 'unpaid') {
          bills = bills.where((bill) => bill.status.toLowerCase() != 'paid').toList();
          _currentUnpaidBills = bills; // 保存当前未支付账单列表
        } else {
          _currentUnpaidBills = []; // 清空未支付账单列表
        }

        if (bills.isEmpty) {
          String emptyMessage = 'No bills record found';
          switch (_selectedFilter) {
            case 'paid':
              emptyMessage = 'No paid bills found';
              break;
            case 'unpaid':
              emptyMessage = 'No unpaid bills found';
              break;
          }
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text(emptyMessage, style: TextStyle(color: Colors.grey[500]))]));
        }

        return FutureBuilder<List<UserModel>>(
          future: FirestoreService.getUsers(),
          builder: (context, usersSnapshot) {
            final users = usersSnapshot.data ?? [];
            final Map<String, UserModel> userById = { for (var u in users) u.id: u };
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

  Widget _buildBillCard(BillModel bill, UserModel? user) {
    final displayName = user?.name ?? bill.payerName;
    final isPaid = bill.status.toLowerCase() == 'paid';
    final isOverdue = bill.status.toLowerCase() == 'overdue';
    final isSelected = _selectedBillIds.contains(bill.id);
    Color statusColor = isPaid ? const Color(0xFF10B981) : (isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));

    IconData categoryIcon = Icons.receipt;
    Color iconBgColor = Colors.blue.withOpacity(0.1);
    Color iconColor = Colors.blue;
    switch (bill.category.toLowerCase()) {
      case 'water': categoryIcon = Icons.water_drop; iconBgColor = Colors.lightBlue.withOpacity(0.1); iconColor = Colors.lightBlue; break;
      case 'electricity': categoryIcon = Icons.flash_on; iconBgColor = Colors.amber.withOpacity(0.1); iconColor = Colors.amber[700]!; break;
      case 'internet': categoryIcon = Icons.wifi; iconBgColor = Colors.purple.withOpacity(0.1); iconColor = Colors.purple; break;
      case 'maintenance': categoryIcon = Icons.build_circle; iconBgColor = Colors.orange.withOpacity(0.1); iconColor = Colors.orange; break;
      case 'parking': categoryIcon = Icons.local_parking; iconBgColor = Colors.indigo.withOpacity(0.1); iconColor = Colors.indigo; break;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: kCardRadius,
        boxShadow: kCardShadow,
        border: _isSelectionMode && isSelected
            ? Border.all(color: primaryColor, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: kCardRadius,
          onTap: _isSelectionMode && _selectedFilter == 'unpaid'
              ? () => _toggleBillSelection(bill.id)
              : (isPaid ? null : () => _showCardActionMenu(bill)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_isSelectionMode && _selectedFilter == 'unpaid') ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) => _toggleBillSelection(bill.id),
                    activeColor: primaryColor,
                  ),
                  const SizedBox(width: 12),
                ],
                Container(width: 50, height: 50, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(14)), child: Icon(categoryIcon, color: iconColor, size: 26)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(bill.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [Icon(Icons.person_outline, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text(displayName, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                    const SizedBox(height: 4),
                    Text(DateFormat('yyyy-MM-dd').format(bill.dueDate), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('RM ${bill.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isPaid ? Colors.black87 : const Color(0xFFEF4444))),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(bill.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleBillSelection(String billId) {
    setState(() {
      if (_selectedBillIds.contains(billId)) {
        _selectedBillIds.remove(billId);
      } else {
        _selectedBillIds.add(billId);
      }
    });
  }

  bool get _isAllSelected {
    // 这里需要获取当前显示的账单数量来判断是否全选
    // 我们需要在_buildBillList中保存当前账单列表的引用
    return _currentUnpaidBills.isNotEmpty && _selectedBillIds.length == _currentUnpaidBills.length;
  }

  List<BillModel> _currentUnpaidBills = [];

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        _selectedBillIds.clear();
      } else {
        _selectedBillIds.addAll(_currentUnpaidBills.map((bill) => bill.id));
      }
    });
  }

  void _showCardActionMenu(BillModel bill) {
    final isPaid = bill.status.toLowerCase() == 'paid';

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          if (isPaid) ...[
            // 显示已支付账单的提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This bill has been paid and cannot be modified.',
                      style: TextStyle(color: Colors.green[800], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 显示编辑和删除选项
            ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit, color: Colors.blue)), title: const Text('Edit Bill'), onTap: () { Navigator.pop(context); _showEditDialog(context, bill: bill); }),
            const Divider(indent: 20, endIndent: 20),
            ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline, color: Colors.red)), title: const Text('Delete Bill'), textColor: Colors.red, onTap: () { Navigator.pop(context); _confirmDelete(bill); }),
          ],
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  // --- GlassContainer 风格的 Dialog (Delete) ---

  Future<void> _confirmDelete(BillModel bill) async {
    final isPaid = bill.status.toLowerCase() == 'paid';

    if (isPaid) {
      // 已支付账单不能删除，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete a paid bill'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), // 背景变暗一点，突出玻璃
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: GlassContainer(
          opacity: 0.9,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.delete_forever_rounded, size: 32, color: Colors.red)),
            const SizedBox(height: 16),
            const Text("Delete Bill", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Are you sure you want to delete this bill? This action cannot be undone.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel"))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => Navigator.pop(c, true), child: const Text("Delete"))),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirestoreService.deleteBill(bill.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedBillIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: GlassContainer(
          opacity: 0.9,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: const Icon(Icons.delete_forever_rounded, size: 32, color: Colors.red)),
            const SizedBox(height: 16),
            Text("Delete ${_selectedBillIds.length} Bills", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Are you sure you want to delete ${_selectedBillIds.length} selected bills? This action cannot be undone.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel"))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => Navigator.pop(c, true), child: const Text("Delete All"))),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        int successCount = 0;
        int failCount = 0;

        for (final billId in _selectedBillIds) {
          try {
            await FirestoreService.deleteBill(billId);
            successCount++;
          } catch (e) {
            failCount++;
          }
        }

        setState(() {
          _selectedBillIds.clear();
          _isSelectionMode = false;
        });

        String message = '$successCount bills deleted successfully';
        if (failCount > 0) {
          message += ', $failCount failed';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bulk delete failed: $e')));
      }
    }
  }

  // --- GlassContainer 风格的 Dialog (Edit/Create) ---

  Future<void> _showEditDialog(BuildContext context, {BillModel? bill}) async {
    if (bill != null && bill.status.toLowerCase() == 'paid') {
      // 已支付账单不能编辑，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit a paid bill'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: bill?.title ?? '');
    final amountCtrl = TextEditingController(text: bill != null ? bill.amount.toString() : '');
    String selectedCategory = bill?.category ?? 'maintenance';
    UserModel? selectedUser;
    final addressCtrl = TextEditingController(text: bill?.propertySimpleAddress ?? '');
    DateTime dueDate = bill?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    DateTime billingDate = bill?.billingDate ?? DateTime.now();

    final users = await FirestoreService.getUsers();
    if (bill != null && bill.userId.isNotEmpty) {
      try { selectedUser = users.firstWhere((user) => user.id == bill.userId); } catch (e) {}
    }
    final List<String> categories = ['maintenance', 'water', 'electricity', 'gas', 'parking', 'management', 'internet'];

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), // 背景变暗一点
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: GlassContainer(
            opacity: 0.9,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(bill == null ? 'New Bill' : 'Edit Bill', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Flexible(
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                        _buildDialogTextField(titleCtrl, 'Title'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<UserModel>(
                          value: selectedUser,
                          decoration: InputDecoration(labelText: 'Payer', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          items: users.map((UserModel user) => DropdownMenuItem(value: user, child: Text(user.name))).toList(),
                          onChanged: (val) => setState(() { selectedUser = val; if (val != null) addressCtrl.text = val.propertySimpleAddress; }),
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(addressCtrl, 'Address'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount (RM)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null) {
                              return 'Please enter a valid number';
                            }
                            if (amount <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                          onChanged: (val) => setState(() => selectedCategory = val!),
                        ),
                        const SizedBox(height: 16),
                        _buildDatePickerRow('Billing Date', billingDate, (d) => setState(() {
                          billingDate = d;
                          // 如果生成日期晚于到期日期，自动调整到期日期
                          if (dueDate.isBefore(billingDate)) {
                            dueDate = billingDate.add(const Duration(days: 1));
                          }
                        })),
                        _buildDatePickerRow('Due Date', dueDate, (d) => setState(() => dueDate = d), minDate: billingDate),
                      ],
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: primaryColor), onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    // 验证到期日期不能早于生成日期
                    if (dueDate.isBefore(billingDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Due date cannot be earlier than billing date'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
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
                      if (bill == null) await FirestoreService.createBill(payload); else await FirestoreService.updateBill(bill.id, payload);
                      Navigator.pop(context);
                    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
                  }, child: const Text('Save'))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime date, Function(DateTime) onSelect, {DateTime? minDate}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        TextButton.icon(icon: const Icon(Icons.calendar_today, size: 16), label: Text(DateFormat('yyyy-MM-dd').format(date)), onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: minDate ?? DateTime(2000),
            lastDate: DateTime(2100)
          );
          if (picked != null) onSelect(picked);
        }),
      ]),
    );
  }
}