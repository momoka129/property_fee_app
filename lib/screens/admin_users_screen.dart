import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart'; // 确保路径正确
import '../widgets/malaysia_phone_input.dart' as mp;
import '../services/avatar_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 核心配色 (与 AdminHome 保持一致)
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);

  ImageProvider? _getUserAvatarImageProvider(UserModel user) {
    if (user.avatar != null && AvatarService.isValidAvatarUrl(user.avatar!)) {
      return NetworkImage(user.avatar!);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== 1. 添加工人的 Glass 弹窗 (保持不变，但为了完整性列出) ====================
  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(20),
              child: GlassContainer(
                width: double.infinity,
                opacity: 0.9,
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
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.engineering_rounded, color: primaryColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Add New Worker',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildGlassTextField(
                      controller: nameController,
                      label: 'Worker Name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    mp.MalaysiaPhoneInput(
                      controller: phoneController,
                      label: 'Phone Number',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Workers do not need a password. They are added to the system for assignment only.",
                              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 12),
                        isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () async {
                            if (nameController.text.isEmpty) return;
                            setStateDialog(() => isLoading = true);
                            try {
                              await FirestoreService.addWorker({
                                'name': nameController.text.trim(),
                                'phoneNumber': phoneController.text.trim(),
                                'role': 'worker',
                                'propertySimpleAddress': 'Staff',
                              });
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Worker added successfully!'), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              setStateDialog(() => isLoading = false);
                            }
                          },
                          child: const Text('Confirm Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 辅助方法：美化弹窗内的输入框
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // ==================== 2. 删除确认弹窗 (已修改为 Glass 风格) ====================
  void _confirmDelete(String id, String name, bool isWorker) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // 背景遮罩
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // 透明背景
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: GlassContainer(
          opacity: 0.9,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded, size: 32, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                isWorker ? 'Delete Worker' : 'Delete Resident',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "$name"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        // 在执行删除前先检查工人是否有未完成的维修任务
                        if (isWorker) {
                          try {
                            final hasActive = await FirestoreService.hasActiveRepairs(id);
                            if (hasActive) {
                              // 关闭确认弹窗并提示无法删除
                              Navigator.pop(context);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This worker has unfinished repair tasks and cannot be deleted'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }
                          } catch (e) {
                            // 检查失败时，继续尝试删除或提示错误
                            Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Check failed: $e')),
                              );
                            }
                            return;
                          }
                        }

                        Navigator.pop(context); // 先关闭弹窗
                        try {
                          if (isWorker) {
                            await FirestoreService.deleteWorker(id);
                          } else {
                            await FirestoreService.deleteUser(id);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Deleted successfully'), backgroundColor: Colors.red),
                            );
                          }
                        } catch (e) {
                          // handle error
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Delete failed: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 2.5 编辑用户弹窗 (已修改为 Glass 风格) ====================
  void _showEditUserDialog(UserModel user, bool isWorker) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');

    String selectedBuilding = 'Alpha Building';
    String selectedFloor = 'G';
    String selectedUnit = '01';

    // 解析地址逻辑保持不变
    try {
      final addr = user.propertySimpleAddress;
      if (addr.isNotEmpty) {
        final parts = addr.split(' ');
        if (parts.length >= 3) {
          selectedBuilding = '${parts[0]} ${parts[1]}';
          final last = parts.sublist(2).join(' ');
          if (last.isNotEmpty) {
            selectedFloor = last[0];
            selectedUnit = last.substring(1);
          }
        } else {
          final match = RegExp(r'([A-Za-z ]+)\s+([G|0-9][0-9])\$').firstMatch(addr);
          if (match != null) {
            selectedBuilding = match.group(1)!.trim();
            final fu = match.group(2)!;
            selectedFloor = fu[0];
            selectedUnit = fu.substring(1);
          }
        }
      }
    } catch (_) {}

    bool isLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent, // 透明背景
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: GlassContainer(
              opacity: 0.9,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(24), // 内边距增加
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题部分
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit_rounded, color: primaryColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isWorker ? 'Edit Worker' : 'Edit Resident',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name
                    _buildGlassTextField(controller: nameController, label: 'Name', icon: Icons.badge_outlined),
                    const SizedBox(height: 16),
                    // Email (only for residents; hide for workers)
                    if (!isWorker) ...[
                      _buildGlassTextField(controller: emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                    ],
                    // Phone
                    if (isWorker) ...[
                      mp.MalaysiaPhoneInput(controller: phoneController, label: 'Phone Number', required: true),
                    ] else ...[
                      mp.MalaysiaPhoneInput(controller: phoneController, label: 'Phone Number', required: false),
                    ],
                    const SizedBox(height: 16),

                    // Address selection
                    if (!isWorker) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Building', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildGlassChoiceChip('Alpha Building', selectedBuilding, (val) => setStateDialog(() => selectedBuilding = val)),
                          _buildGlassChoiceChip('Beta Building', selectedBuilding, (val) => setStateDialog(() => selectedBuilding = val)),
                          _buildGlassChoiceChip('Central Building', selectedBuilding, (val) => setStateDialog(() => selectedBuilding = val)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassDropdown(
                              label: 'Floor',
                              value: selectedFloor,
                              items: ['G', '1', '2', '3', '4', '5'],
                              onChanged: (v) => setStateDialog(() => selectedFloor = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGlassDropdown(
                              label: 'Unit',
                              value: selectedUnit,
                              items: ['01', '02'],
                              onChanged: (v) => setStateDialog(() => selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 8),
                              Text('Address: ${user.propertySimpleAddress}', style: TextStyle(color: Colors.grey[800])),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 12),
                        isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : FilledButton(
                          onPressed: () async {
                            // 保存逻辑保持不变
                            final name = nameController.text.trim();
                            final email = emailController.text.trim();
                            final phone = phoneController.text.trim();
                            if (name.isEmpty || email.isEmpty) return;

                            setStateDialog(() => isLoading = true);

                            if (!isWorker) {
                              final composedAddress = '$selectedBuilding ${selectedFloor}${selectedUnit}';
                              final addressExists = await FirestoreService.checkAddressExists(composedAddress, excludeUserId: user.id);
                              if (addressExists) {
                                setStateDialog(() => isLoading = false);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address already in use'), backgroundColor: Colors.red));
                                return;
                              }
                            }

                            if (!isWorker) {
                              final emailExists = await FirestoreService.checkEmailExists(email, excludeUserId: user.id);
                              if (emailExists) {
                                setStateDialog(() => isLoading = false);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email already in use'), backgroundColor: Colors.red));
                                return;
                              }
                            }

                            if (phone.isNotEmpty) {
                              final phoneExists = await FirestoreService.checkPhoneExists(phone, excludeUserId: user.id);
                              if (phoneExists) {
                                setStateDialog(() => isLoading = false);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number already in use'), backgroundColor: Colors.red));
                                return;
                              }
                            }

                            try {
                            // For workers we do not include email in the payload (remove email field for workers)
                            final payload = {'name': name, 'phoneNumber': phone};
                            if (!isWorker) {
                              payload['email'] = email;
                              payload['propertySimpleAddress'] = '$selectedBuilding ${selectedFloor}${selectedUnit}';
                            }

                              if (isWorker) {
                                await FirestoreService.updateWorker(user.id, payload);
                              } else {
                                await FirestoreService.updateUser(user.id, payload);
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green));
                                setState(() {});
                              }
                            } catch (e) {
                              setStateDialog(() => isLoading = false);
                            }
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // 辅助组件：Glass 风格的 ChoiceChip
  Widget _buildGlassChoiceChip(String label, String selectedValue, Function(String) onSelected) {
    final isSelected = selectedValue == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(label),
      selectedColor: primaryColor.withOpacity(0.2),
      backgroundColor: Colors.white.withOpacity(0.5),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? primaryColor : Colors.transparent),
      ),
      elevation: 0,
    );
  }

  // 辅助组件：Glass 风格的 Dropdown
  Widget _buildGlassDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
        ),
      ),
    );
  }

  // ==================== 3. 主页面构建 (保持不变) ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
        onPressed: _showAddWorkerDialog,
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text("Add Worker"),
      )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Manage Users',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Residents'),
                    Tab(text: 'Workers'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResidentsList(),
                    _buildWorkersList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentsList() {
    return FutureBuilder<List<UserModel>>(
      future: FirestoreService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No residents found.");
        }

        final users = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], isWorker: false);
          },
        );
      },
    );
  }

  Widget _buildWorkersList() {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService.getWorkersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workers = snapshot.data ?? [];
        if (workers.isEmpty) {
          return _buildEmptyState("No workers yet. Tap '+ Add Worker' to start.");
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildUserCard(workers[index], isWorker: true);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, {required bool isWorker}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          onTap: () => _showEditUserDialog(user, isWorker),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: _getUserAvatarImageProvider(user),
            backgroundColor: isWorker ? Colors.orange.shade50 : Colors.blue.shade50,
            child: _getUserAvatarImageProvider(user) == null
                ? Icon(
              isWorker ? Icons.engineering : Icons.person,
              color: isWorker ? Colors.orange : primaryColor,
              size: 24,
            )
                : null,
          ),
          title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(user.phoneNumber!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              if (!isWorker && user.email.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(user.email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.8)),
            onPressed: () => _confirmDelete(user.id, user.name, isWorker),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}