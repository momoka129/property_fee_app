import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart'; // 确保路径正确

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 监听 Tab 切换以刷新 FAB 按钮的显示状态
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== 1. 添加工人的 Glass 弹窗 ====================
  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // 背景遮罩稍微深一点，突出玻璃效果
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent, // 背景透明，交给 GlassContainer
              elevation: 0,
              insetPadding: const EdgeInsets.all(20),
              child: GlassContainer(
                width: double.infinity,
                opacity: 0.9, // 不透明度高一点，保证内容清晰
                blur: 20,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 输入框 Name
                    _buildGlassTextField(
                      controller: nameController,
                      label: 'Worker Name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),

                    // 输入框 Phone
                    _buildGlassTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // 提示文字
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

                    // 按钮组
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 12),
                        isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
                              // 核心逻辑：调用 addWorker (存入 workers 集合)
                              await FirestoreService.addWorker({
                                'name': nameController.text.trim(),
                                'phoneNumber': phoneController.text.trim(),
                                'role': 'worker',
                                'propertySimpleAddress': 'Staff',
                                // 不传 email，因为不需要登录
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Worker added successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setStateDialog(() => isLoading = false);
                              // 错误提示
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
        fillColor: Colors.white.withOpacity(0.5), // 半透明白色底
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // ==================== 2. 删除确认弹窗 ====================
  void _confirmDelete(String id, String name, bool isWorker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWorker ? 'Delete Worker' : 'Delete Resident'),
        content: Text('Are you sure you want to delete "$name"?\nThis action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 先关闭弹窗
              try {
                if (isWorker) {
                  await FirestoreService.deleteWorker(id); // 删除工人
                } else {
                  await FirestoreService.deleteUser(id); // 删除住户
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleted successfully')),
                  );
                }
              } catch (e) {
                // handle error
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==================== 2.5 编辑用户弹窗 ====================
  void _showEditUserDialog(UserModel user, bool isWorker) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');
    // Address selection state (use same options as RegisterScreen)
    String selectedBuilding = 'Alpha Building';
    String selectedFloor = 'G';
    String selectedUnit = '01';

    // Try parse existing propertySimpleAddress like "Alpha Building G01"
    try {
      final addr = user.propertySimpleAddress;
      if (addr.isNotEmpty) {
        // split by space: ["Alpha", "Building", "G01"] or "Alpha Building G01"
        final parts = addr.split(' ');
        if (parts.length >= 3) {
          selectedBuilding = '${parts[0]} ${parts[1]}';
          final last = parts.sublist(2).join(' ');
          // last expected like G01
          if (last.isNotEmpty) {
            selectedFloor = last[0];
            selectedUnit = last.substring(1);
          }
        } else {
          // fallback: attempt to extract floor+unit at end
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
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWorker ? 'Edit Worker' : 'Edit Resident',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    _buildGlassTextField(controller: nameController, label: 'Name', icon: Icons.badge_outlined),
                    const SizedBox(height: 12),
                    // Email
                    _buildGlassTextField(controller: emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    // Phone
                    _buildGlassTextField(controller: phoneController, label: 'Phone Number', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),

                    // Address selection (only for residents). For workers, keep as static text.
                    if (!isWorker) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Building', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Alpha Building'),
                            selected: selectedBuilding == 'Alpha Building',
                            onSelected: (_) => setStateDialog(() => selectedBuilding = 'Alpha Building'),
                          ),
                          ChoiceChip(
                            label: const Text('Beta Building'),
                            selected: selectedBuilding == 'Beta Building',
                            onSelected: (_) => setStateDialog(() => selectedBuilding = 'Beta Building'),
                          ),
                          ChoiceChip(
                            label: const Text('Central Building'),
                            selected: selectedBuilding == 'Central Building',
                            onSelected: (_) => setStateDialog(() => selectedBuilding = 'Central Building'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Floor + Unit selection
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedFloor,
                                  items: const [
                                    DropdownMenuItem(value: 'G', child: Text('G')),
                                    DropdownMenuItem(value: '1', child: Text('1')),
                                    DropdownMenuItem(value: '2', child: Text('2')),
                                    DropdownMenuItem(value: '3', child: Text('3')),
                                    DropdownMenuItem(value: '4', child: Text('4')),
                                    DropdownMenuItem(value: '5', child: Text('5')),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setStateDialog(() => selectedFloor = v);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedUnit,
                                  items: const [
                                    DropdownMenuItem(value: '01', child: Text('01')),
                                    DropdownMenuItem(value: '02', child: Text('02')),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setStateDialog(() => selectedUnit = v);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      // For workers show current address (read-only)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Text('Address: ${user.propertySimpleAddress}', style: TextStyle(color: Colors.grey[700])),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
                        const SizedBox(width: 12),
                        isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : FilledButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final phone = phoneController.text.trim();
                                  if (name.isEmpty || email.isEmpty) return;

                                  setStateDialog(() => isLoading = true);

                                  // Check if address is already in use by another user (only for residents, not workers)
                                  if (!isWorker) {
                                    final composedAddress = '$selectedBuilding ${selectedFloor}${selectedUnit}';
                                    final addressExists = await FirestoreService.checkAddressExists(composedAddress, excludeUserId: user.id);
                                    if (addressExists) {
                                      setStateDialog(() => isLoading = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('This property address is already in use by another resident.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  // Check if email is already in use by another user (only for residents, not workers)
                                  if (!isWorker) {
                                    final emailExists = await FirestoreService.checkEmailExists(email, excludeUserId: user.id);
                                    if (emailExists) {
                                      setStateDialog(() => isLoading = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('This email is already in use by another user.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  try {
                                    final payload = {
                                      'name': name,
                                      'email': email,
                                      'phoneNumber': phone,
                                      // DO NOT include 'role' or 'avatar' here
                                    };

                                    if (!isWorker) {
                                      final composedAddress = '$selectedBuilding ${selectedFloor}${selectedUnit}';
                                      payload['propertySimpleAddress'] = composedAddress;
                                    }

                                    if (isWorker) {
                                      await FirestoreService.updateWorker(user.id, payload);
                                    } else {
                                      await FirestoreService.updateUser(user.id, payload);
                                    }

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully'), backgroundColor: Colors.green));
                                      setState(() {}); // refresh lists
                                    }
                                  } catch (e) {
                                    setStateDialog(() => isLoading = false);
                                    // optionally show error
                                  }
                                },
                                child: const Text('Save'),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
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

  // ==================== 3. 主页面构建 ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // 只有在 Workers 标签页才显示 FAB
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
              // 自定义 Header
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

              // 自定义 TabBar
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

              // 列表内容
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResidentsList(), // 住户列表 (FutureBuilder)
                    _buildWorkersList(),   // 工人列表 (StreamBuilder - 实时更新)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建住户列表
  Widget _buildResidentsList() {
    return FutureBuilder<List<UserModel>>(
      future: FirestoreService.getUsers(), // 假设这是获取住户的方法
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

  // 构建工人列表 (使用 StreamBuilder 实现实时刷新)
  Widget _buildWorkersList() {
    return StreamBuilder<List<UserModel>>(
      // 注意：这里必须使用 Stream 才能看到刚刚添加的数据
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), // 底部留出 FAB 的空间
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildUserCard(workers[index], isWorker: true);
          },
        );
      },
    );
  }

  // 通用列表卡片样式
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
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isWorker ? Colors.orange.shade50 : Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWorker ? Icons.engineering : Icons.person,
              color: isWorker ? Colors.orange : primaryColor,
              size: 24,
            ),
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
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}