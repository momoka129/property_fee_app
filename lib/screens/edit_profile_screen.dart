import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../data/mock_data.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../services/avatar_service.dart';
import '../utils/url_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _propertyAddressController;
  String? _selectedAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = MockData.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _propertyAddressController = TextEditingController(text: user.propertySimpleAddress);
    _selectedAvatarPath = user.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _propertyAddressController.dispose();
    super.dispose();
  }

  ImageProvider? _getAvatarImageProvider() {
    if (_selectedAvatarPath != null && _isValidAvatarPath(_selectedAvatarPath!)) {
      // 如果是本地文件路径
      if (_selectedAvatarPath!.startsWith('/')) {
        return FileImage(File(_selectedAvatarPath!));
      }
      // 如果是网络URL
      else if (isValidImageUrl(_selectedAvatarPath!)) {
        return NetworkImage(_selectedAvatarPath!);
      }
    }
    return null;
  }

  bool _isValidAvatarPath(String path) {
    if (path.startsWith('/')) {
      return AvatarService.isValidAvatarPath(path);
    } else {
      return isValidImageUrl(path);
    }
  }

  Future<void> _changePhoto() async {
    final user = MockData.currentUser!;
    final avatarPath = await AvatarService.pickAndSaveAvatar(context, user.id);

    if (avatarPath != null) {
      setState(() {
        _selectedAvatarPath = avatarPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('头像已更新'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (MockData.currentUser != null) {
          final updatedUser = MockData.currentUser!.copyWith(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            propertySimpleAddress: _propertyAddressController.text.trim(),
            avatar: _selectedAvatarPath,
          );

          // 更新Firebase数据库
          await FirestoreService.updateUser(updatedUser.id, {
            'name': updatedUser.name,
            'phoneNumber': updatedUser.phoneNumber,
            'propertySimpleAddress': updatedUser.propertySimpleAddress,
            'avatar': updatedUser.avatar,
          });

          // 通过Provider更新本地数据，触发UI刷新
          context.read<AppProvider>().updateUser(updatedUser);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppProvider>().getLocalizedText('save') + ' ' +
                         context.read<AppProvider>().getLocalizedText('name') + ' ' +
                         context.read<AppProvider>().getLocalizedText('confirm') + '!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser!;
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appProvider.getLocalizedText('edit_profile')),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _getAvatarImageProvider(),
                    child: _selectedAvatarPath == null || !_isValidAvatarPath(_selectedAvatarPath!)
                        ? Text(
                            // Guard against empty name to avoid RangeError when accessing [0]
                            (user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                            style: const TextStyle(fontSize: 40),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _changePhoto(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Change Photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${appProvider.getLocalizedText('name')} *',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _propertyAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Property Address *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
                hintText: 'e.g., Alpha Building G01',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your property address';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saveProfile,
                child: Text(appProvider.getLocalizedText('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

