import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  // 统一 UI 风格变量
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

  // 更新包裹状态
  Future<void> _updatePackageStatus(String packageId, String status) async {
    try {
      await FirestoreService.updatePackageStatus(packageId, status); // 需确保 Service 有此方法，如果没有可用 updatePackage
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Fallback if specific method doesn't exist
      try {
        await FirestoreService.updatePackage(packageId, {'status': status});
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e2) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e2')));
        }
      }
    }
  }

  // 删除包裹
  Future<void> _deletePackage(String packageId) async {
    try {
      await FirestoreService.deletePackage(packageId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package deleted'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                child: _buildPackageList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPackageDialog(context),
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_box_outlined, color: Colors.white),
        label: const Text('New Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            'Parcel Management',
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

  // --- 2. 包裹列表 ---
  Widget _buildPackageList() {
    return StreamBuilder<List<PackageModel>>(
      stream: FirestoreService.getAllPackagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final packages = snapshot.data ?? [];
        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No packages logged', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return FutureBuilder<List<UserModel>>(
          future: FirestoreService.getUsers(),
          builder: (context, userSnapshot) {
            final users = userSnapshot.data ?? [];
            final userMap = {for (var u in users) u.id: u};

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), // bottom padding for FAB
              physics: const BouncingScrollPhysics(),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final package = packages[index];
                final user = userMap[package.userId];
                return _buildPackageCard(package, user);
              },
            );
          },
        );
      },
    );
  }

  // --- 3. 包裹卡片 ---
  Widget _buildPackageCard(PackageModel package, UserModel? user) {
    final isReady = package.status == 'ready_for_pickup';
    

    return GlassContainer(
      borderRadius: kCardRadius,
      blur: 12,
      opacity: isReady ? 0.6 : 0.55,
      padding: const EdgeInsets.all(16),
      onTap: () => _showActionSheet(context, package, user),
      child: Row(
        children: [
          // 左侧方形图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(Icons.inventory_2_outlined, color: Colors.black54, size: 26),
            ),
          ),
          const SizedBox(width: 16),
          // 中间信息（标题 + 描述 + 追踪 + 地址）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.courier,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  package.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tracking: ${package.trackingNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user?.propertySimpleAddress ?? package.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 右侧等待天数 badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isReady ? const Color(0xFFECFDF3) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isReady ? const Color(0xFF10B981).withOpacity(0.2) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isReady ? const Color(0xFF10B981) : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${package.waitingDays}d',
                      style: TextStyle(
                        color: isReady ? const Color(0xFF10B981) : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('MMM dd').format(package.arrivedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. 底部操作菜单 ---
  void _showActionSheet(BuildContext context, PackageModel package, UserModel? user) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Parcel",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4),
            Text(
              "Tracking: ${package.trackingNumber}",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),

            if (package.status == 'ready_for_pickup')
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check_circle_outline, color: Colors.green),
                ),
                title: const Text('Mark as Collected'),
                subtitle: const Text('Resident has picked up the item'),
                onTap: () => _updatePackageStatus(package.id, 'collected'),
              ),

            const Divider(),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              title: const Text('Delete Record'),
              textColor: Colors.red,
              onTap: () => _showDeleteConfirm(package.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Parcel'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(c); // close dialog
              _deletePackage(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPackageDialog(BuildContext context) async {
    final users = await FirestoreService.getUsers();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => _AddPackageDialog(users: users),
    );
  }
}

// --- 5. 新增包裹弹窗 ---
class _AddPackageDialog extends StatefulWidget {
  final List<UserModel> users;
  const _AddPackageDialog({required this.users});

  @override
  State<_AddPackageDialog> createState() => _AddPackageDialogState();
}

class _AddPackageDialogState extends State<_AddPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  UserModel? _selectedUser;
  final _courierController = TextEditingController();
  final _trackingController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // 样式变量
  final outlineBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  @override
  Widget build(BuildContext context) {
    // 1. 用 Dialog 替换 AlertDialog
    return Dialog(
      backgroundColor: Colors.transparent, // 背景透明，否则玻璃效果出不来
      elevation: 0, // 去掉默认阴影
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // 防止贴边

      // 2. 使用你的 GlassContainer
      child: GlassContainer(
        opacity: 0.9, // 稍微实一点，保证表单看不晕
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),

        // 3. 手动用 Column 重新布局：标题 + 表单 + 按钮
        child: Column(
          mainAxisSize: MainAxisSize.min, // 也就是 wrap_content
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 标题部分 ---
            const Text(
                'Incoming Parcel',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),

            const SizedBox(height: 20),

            // --- 内容部分 (可滚动) ---
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<UserModel>(
                        decoration: InputDecoration(
                          labelText: 'Resident',
                          border: outlineBorder,
                          enabledBorder: outlineBorder,
                          prefixIcon: const Icon(Icons.person_outline),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        value: _selectedUser,
                        items: widget.users.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text(
                              '${user.name} (${user.propertySimpleAddress})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedUser = val),
                        validator: (val) => val == null ? 'Please select a resident' : null,
                        isExpanded: true,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_courierController, 'Courier (e.g. DHL)', Icons.local_shipping_outlined),
                      const SizedBox(height: 12),
                      _buildTextField(_trackingController, 'Tracking Number', Icons.qr_code),
                      const SizedBox(height: 12),
                      _buildTextField(_descriptionController, 'Description (e.g. Small Box)', Icons.description_outlined),
                      const SizedBox(height: 12),
                      // Location is fixed and not editable by admin
                      TextFormField(
                        initialValue: 'Management Office',
                        decoration: InputDecoration(
                          labelText: 'Location',
                          border: outlineBorder,
                          enabledBorder: outlineBorder,
                          prefixIcon: Icon(Icons.place_outlined, size: 20, color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- 按钮部分 (原本的 actions) ---
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF4F46E5),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add Record'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final packageData = {
          'userId': _selectedUser!.id,
          'courier': _courierController.text.trim(),
          'trackingNumber': _trackingController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': 'Management Office',
          'status': 'ready_for_pickup',
          'arrivedAt': DateTime.now(),
          'image': null,
        };

        await FirestoreService.createPackage(packageData);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Package added successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}