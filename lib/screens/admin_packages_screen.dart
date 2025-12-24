import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Management'),
      ),
      body: StreamBuilder<List<PackageModel>>(
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
            return const Center(child: Text('No packages found'));
          }

          // 获取用户信息以显示包裹属于谁
          return FutureBuilder<List<UserModel>>(
            future: FirestoreService.getUsers(),
            builder: (context, userSnapshot) {
              final users = userSnapshot.data ?? [];
              final userMap = {for (var u in users) u.id: u};

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final package = packages[index];
                  final user = userMap[package.userId];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: package.status == 'ready_for_pickup'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        child: Icon(
                          Icons.inventory_2,
                          color: package.status == 'ready_for_pickup' ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text('${package.courier} - ${package.trackingNumber}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To: ${user?.name ?? 'Unknown'} (${user?.propertySimpleAddress ?? 'N/A'})'),
                          Text(package.description),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(package.arrivedAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          package.statusDisplay,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: package.status == 'ready_for_pickup'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPackageDialog(context),
        label: const Text('Add Package'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPackageDialog(BuildContext context) async {
    // 预先加载用户列表
    final users = await FirestoreService.getUsers();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _AddPackageDialog(users: users),
    );
  }
}

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
  final _locationController = TextEditingController(text: 'Management Office');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Package'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<UserModel>(
                decoration: const InputDecoration(
                  labelText: 'Resident',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                value: _selectedUser,
                items: widget.users.map((user) {
                  return DropdownMenuItem(
                    value: user,
                    child: Text(
                      '${user.name} (${user.propertySimpleAddress})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedUser = val),
                validator: (val) => val == null ? 'Please select a resident' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courierController,
                decoration: const InputDecoration(
                  labelText: 'Courier (e.g. DHL, PosLaju)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trackingController,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (e.g. Small Box)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Package'),
        ),
      ],
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
          'location': _locationController.text.trim(),
          'status': 'ready_for_pickup',
          'arrivedAt': DateTime.now(),
          'image': null, // 图片上传功能暂未实现，设为null
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