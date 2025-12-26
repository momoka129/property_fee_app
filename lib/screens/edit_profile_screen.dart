import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:property_fee_app/widgets/malaysia_phone_input.dart' as mp;
import '../data/mock_data.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_container.dart';
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
  String _selectedBuilding = 'Alpha Building';
  String _selectedFloor = 'G';
  String _selectedUnit = '01';
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    final user = MockData.currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _selectedAvatarUrl = user.avatar;

    // Only parse address for resident users. Admin/management accounts don't use property selectors.
    if (user.role != 'admin') {
      // Parse existing address to initialize selectors
      final address = user.propertySimpleAddress;
      if (address.isNotEmpty) {
        try {
          // split by space: ["Alpha", "Building", "G01"] or "Alpha Building G01"
          final parts = address.split(' ');
          if (parts.length >= 3) {
            _selectedBuilding = '${parts[0]} ${parts[1]}';
            final last = parts.sublist(2).join(' ');
            // last expected like G01
            if (last.isNotEmpty) {
              _selectedFloor = last[0];
              _selectedUnit = last.substring(1);
            }
          } else {
            // fallback: attempt to extract floor+unit at end
            final match = RegExp(r'([A-Za-z ]+)\s+([G|0-9][0-9])\$').firstMatch(address);
            if (match != null) {
              _selectedBuilding = match.group(1)!.trim();
              final fu = match.group(2)!;
              _selectedFloor = fu[0];
              _selectedUnit = fu.substring(1);
            }
          }
        } catch (_) {
          // If parsing fails, keep default values
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
      try {
        await FirestoreService.updateUserAvatar(user.id, avatarUrl);
        // 通过Provider更新本地数据，触发UI刷新（确保其他页面也能马上看到变更）
        if (context.mounted) {
          context.read<AppProvider>().updateUser(updatedUser);
        }
      } catch (e) {
        debugPrint('Failed to update avatar in Firestore: $e');
      }

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
          final currentUser = MockData.currentUser!;
          // For admin users, keep their existing address string unchanged and skip address checks
          final newAddress = (currentUser.role == 'admin')
              ? currentUser.propertySimpleAddress
              : '$_selectedBuilding $_selectedFloor$_selectedUnit';

          // Check if the new address is already in use by another user (only for residents)
          if (currentUser.role != 'admin' && newAddress != currentUser.propertySimpleAddress) {
            final addressExists = await FirestoreService.checkAddressExists(newAddress, excludeUserId: currentUser.id);
            if (addressExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This property address is already in use by another resident.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }

          // Check if the new phone number is already in use by another user
          final newPhone = _phoneController.text.trim();
          if (newPhone.isNotEmpty && newPhone != (currentUser.phoneNumber ?? '')) {
            final phoneExists = await FirestoreService.checkPhoneExists(newPhone, excludeUserId: currentUser.id);
            if (phoneExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This phone number is already in use by another account.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }

          // For admin, do not change propertySimpleAddress (management office string kept as-is)
          final updatedUser = currentUser.copyWith(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            propertySimpleAddress: newAddress,
            avatar: _selectedAvatarUrl,
          );

          // 更新Firebase数据库. Skip propertySimpleAddress update for admin accounts.
          final updateMap = {
            'name': updatedUser.name,
            'phoneNumber': updatedUser.phoneNumber,
            'avatar': updatedUser.avatar,
          };
          if (currentUser.role != 'admin') {
            updateMap['propertySimpleAddress'] = updatedUser.propertySimpleAddress;
          }
          await FirestoreService.updateUser(updatedUser.id, updateMap);

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
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 24),

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

                  // Use MalaysiaPhoneInput for consistent phone input UI (optional field)
                  mp.MalaysiaPhoneInput(
                    controller: _phoneController,
                    label: 'Phone Number',
                    required: false,
                    // keep existing behavior: empty allowed
                    validator: (v) {
                      final txt = _phoneController.text.trim();
                      if (txt.isNotEmpty && txt.length != 9) return 'Phone must be 9 digits';
                      return null;
                    },
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 16),

                  // Building/floor/unit selectors are only shown for resident users
                  if (user.role != 'admin') ...[
                    // Building selection (choose one of three buildings inline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Building', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Alpha Building'),
                          selected: _selectedBuilding == 'Alpha Building',
                          onSelected: (_) => setState(() => _selectedBuilding = 'Alpha Building'),
                        ),
                        ChoiceChip(
                          label: const Text('Beta Building'),
                          selected: _selectedBuilding == 'Beta Building',
                          onSelected: (_) => setState(() => _selectedBuilding = 'Beta Building'),
                        ),
                        ChoiceChip(
                          label: const Text('Central Building'),
                          selected: _selectedBuilding == 'Central Building',
                          onSelected: (_) => setState(() => _selectedBuilding = 'Central Building'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Floor + Unit selection (Floor: G..5, Unit: 01/02)
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Floor', border: OutlineInputBorder()),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFloor,
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
                                  setState(() => _selectedFloor = v);
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
                                value: _selectedUnit,
                                items: const [
                                  DropdownMenuItem(value: '01', child: Text('01')),
                                  DropdownMenuItem(value: '02', child: Text('02')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedUnit = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

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
          ],
        ),
      ),
    );
  }
}

