// lib/screens/home_tabs/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/user_model.dart';
import '../../routes.dart';
import '../../providers/app_provider.dart';
import '../../services/avatar_service.dart';
import '../../utils/url_utils.dart';
import '../../widgets/glass_container.dart';
import '../../data/mock_data.dart'; // 需要引入 MockData

// 将 _ProfilePage 改名为 ProfileTab
class ProfileTab extends StatelessWidget {
  final UserModel user;
  final AppProvider appProvider;

  const ProfileTab({super.key, required this.user, required this.appProvider});

  ImageProvider? _getAvatarImageProvider(String? avatarPath) {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      if (avatarPath.startsWith('/')) {
        if (AvatarService.isValidAvatarPath(avatarPath)) {
          return FileImage(File(avatarPath));
        }
      } else if (isValidImageUrl(avatarPath)) {
        return CachedNetworkImageProvider(avatarPath);
      }
    }
    return null;
  }

  // 辅助方法：构建玻璃风格的列表项
  Widget _buildGlassListTile(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(
          title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.black54))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }

  // 辅助方法：构建信息行
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 辅助方法：构建分割线
  Widget _buildDivider() {
    return Divider(
        height: 1,
        color: Colors.grey.withOpacity(0.2),
        indent: 56,
        endIndent: 20
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final Color bgGradientStart = const Color(0xFFF3F4F6);
    final Color bgGradientEnd = const Color(0xFFE5E7EB);

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final currentUser = appProvider.currentUser ?? user;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  MockData.currentUser = null;
                  appProvider.updateUser(null as UserModel?);
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgGradientStart, bgGradientEnd],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 10),
                  // User Info Area
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            backgroundImage: _getAvatarImageProvider(currentUser.avatar),
                            child: (currentUser.avatar == null ||
                                (!isValidImageUrl(currentUser.avatar!) &&
                                    !AvatarService.isValidAvatarPath(currentUser.avatar!)))
                                ? Text(
                              currentUser.name
                                  .split(' ')
                                  .where((part) => part.isNotEmpty)
                                  .map((part) => part[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor),
                            )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Property Info
                  GlassContainer(
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Property Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildInfoRow(context, Icons.home_rounded, 'Address', currentUser.propertySimpleAddress),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, Icons.phone_rounded, 'Phone', currentUser.phoneNumber ?? 'Not set'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu Options
                  GlassContainer(
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildGlassListTile(
                          context,
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                        ),
                        _buildDivider(),
                        _buildGlassListTile(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                        ),
                        _buildDivider(),
                        _buildGlassListTile(
                          context,
                          icon: Icons.credit_card_rounded,
                          title: 'Payment Methods',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.managePaymentMethods);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About
                  GlassContainer(
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildGlassListTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                        ),
                        _buildDivider(),
                        _buildGlassListTile(
                          context,
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: 'Version 1.0.0',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}