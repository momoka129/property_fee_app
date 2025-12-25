import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../services/avatar_service.dart';

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
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    final user = MockData.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _propertyAddressController = TextEditingController(text: user.propertySimpleAddress);
    _selectedAvatarUrl = user.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _propertyAddressController.dispose();
    super.dispose();
  }

  ImageProvider? _getAvatarImageProvider() {
    if (_selectedAvatarUrl != null && AvatarService.isValidAvatarUrl(_selectedAvatarUrl!)) {
      return NetworkImage(_selectedAvatarUrl!);
    }
    return null;
  }

  bool _isValidAvatarUrl(String url) {
    return AvatarService.isValidAvatarUrl(url);
  }

  Future<void> _changePhoto() async {
    final user = MockData.currentUser!;
    final avatarUrl = await AvatarService.pickAndUploadAvatar(context, user.id);

    if (avatarUrl != null) {
      // 更新本地用户数据
      final updatedUser = user.copyWith(avatar: avatarUrl);
      MockData.currentUser = updatedUser;

      setState(() {
        _selectedAvatarUrl = avatarUrl;
      });

      // 更新用户头像到Firestore
      await FirestoreService.updateUserAvatar(user.id, avatarUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated'),
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
            avatar: _selectedAvatarUrl,
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
            content: Text('Save name confirm!'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
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
                    child: _selectedAvatarUrl == null || !_isValidAvatarUrl(_selectedAvatarUrl!)
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
                labelText: 'Name *',
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
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

