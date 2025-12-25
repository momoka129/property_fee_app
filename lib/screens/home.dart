import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../data/mock_data.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../models/package_model.dart';
import '../models/bill_model.dart';
import '../services/firestore_service.dart';
import '../routes.dart';
import '../providers/app_provider.dart';
import '../services/avatar_service.dart';
import '../utils/url_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    // 监听路由变化，当从其他页面返回时刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 使用路由观察者来监听页面返回
    });
  }


  @override
  Widget build(BuildContext context) {
    // 使用Consumer监听用户数据变化
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final currentUser = appProvider.currentUser;
        
        // 如果没有登录用户，跳转到登录页
        if (currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = [
          _DashboardPage(

            user: currentUser,
            appProvider: appProvider,
          ),
          _ServicesPage(appProvider: appProvider),
          _ProfilePage(user: currentUser, appProvider: appProvider),
        ];

        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                // 切换到主页时刷新数据

              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: appProvider.getLocalizedText('home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.apps_outlined),
                selectedIcon: const Icon(Icons.apps),
                label: appProvider.getLocalizedText('services'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: appProvider.getLocalizedText('profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardPage extends StatefulWidget {
  final UserModel user;
  final AppProvider appProvider;

  const _DashboardPage({super.key, required this.user, required this.appProvider});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  // --- 新增代码开始 ---
  @override
  void initState() {
    super.initState();
    // 页面加载完成后，立刻在后台检查逾期账单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 使用 widget.user.id 获取当前用户ID
      FirestoreService.checkAndProcessOverdueBills(widget.user.id);
    });
  }
  // --- 新增代码结束 ---
  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final appProvider = widget.appProvider;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${appProvider.getLocalizedText('home')}, ${user.name.split(' ').first}! 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appProvider.getLocalizedText('unit')} ${user.propertySimpleAddress}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            // --- 修改开始：替换原来的 IconButton ---
            StreamBuilder<int>(
              // 监听当前用户的未读通知数量
              stream: FirestoreService.getUnreadNotificationCountStream(user.id),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // 点击跳转到我们在 routes.dart 里注册的 notifications 页面
                        Navigator.pushNamed(context, AppRoutes.notifications);
                      },
                    ),
                    // 如果有未读消息，显示红点
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // --- 修改结束 ---
            const SizedBox(width: 8), // 加一点右边距
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Quick Stats
              _buildQuickStats(context, appProvider),
              const SizedBox(height: 24),

              // Urgent Notifications
              _buildUrgentNotifications(context, appProvider),

              // Recent Announcements
              _buildRecentAnnouncements(context, appProvider),

              // Quick Actions
              _buildQuickActions(context, appProvider),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, AppProvider appProvider) {
        // 首先尝试按 userId 查询账单；若无结果则按 propertySimpleAddress 回退
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getUserBillsStream(widget.user.id),
      builder: (context, billsSnapshot) {
        if (billsSnapshot.connectionState == ConnectionState.waiting) {
          // 仍然同时展示包裹数量为占位（保持原有 UX）
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(context, appProvider.getLocalizedText('unpaid_bills'), '...', Icons.receipt_long, Colors.orange, false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(context, appProvider.getLocalizedText('packages'), '...', Icons.inventory_2, Colors.blue, false),
                ),
              ],
            ),
          );
        }

        final primaryBills = billsSnapshot.data ?? [];

        // 如果 primary 查询到数据则使用它；否则使用按 propertyUnit 回退查询
        final billsStreamToUse = primaryBills.isNotEmpty
            ? Stream<List<BillModel>>.value(primaryBills)
            : FirestoreService.getUserBillsByPropertyAddressStream(widget.user.propertySimpleAddress);

        return StreamBuilder<List<BillModel>>(
          stream: billsStreamToUse,
          builder: (context, finalBillsSnapshot) {
            return StreamBuilder<List<PackageModel>>(
              stream: FirestoreService.getUserPackagesStream(widget.user.id),
              builder: (context, packagesSnapshot) {
                final bills = finalBillsSnapshot.data ?? [];
                final packages = packagesSnapshot.data ?? [];

                final unpaidBills = bills.where((b) => b.status == 'unpaid').toList();
                final unpaidTotal = unpaidBills.fold<double>(0, (sum, b) => sum + b.amount);
                final readyPackages = packages.where((p) => p.status == 'ready_for_pickup').toList();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          appProvider.getLocalizedText('unpaid_bills'),
                          finalBillsSnapshot.connectionState == ConnectionState.waiting
                              ? '...'
                              : 'RM ${unpaidTotal.toStringAsFixed(0)}',
                          Icons.receipt_long,
                          Colors.orange,
                          unpaidBills.isNotEmpty,
                          onTap: () async {
                            await Navigator.pushNamed(context, AppRoutes.bills);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          appProvider.getLocalizedText('packages'),
                          packagesSnapshot.connectionState == ConnectionState.waiting ? '...' : '${readyPackages.length}',
                          Icons.inventory_2,
                          Colors.blue,
                          readyPackages.isNotEmpty,
                          onTap: () async {
                            await Navigator.pushNamed(context, AppRoutes.packages);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool hasNotification, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (hasNotification)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentNotifications(BuildContext context, AppProvider appProvider) {
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getUserBillsStream(widget.user.id),
      builder: (context, billsSnapshot) {
        final bills = billsSnapshot.data ?? [];
        final unpaidBills = bills.where((b) => b.status == 'unpaid').toList();

        // 如果没有未付账单，就不显示这个区域
        if (unpaidBills.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Needs Attention',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(
                context,
                Icons.warning_amber_rounded,
                Colors.orange,
                'Unpaid Bills',
                'You have ${unpaidBills.length} unpaid bill(s)',
                () => Navigator.pushNamed(context, AppRoutes.bills),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAnnouncements(BuildContext context, AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community News',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.announcements),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Load top 3 announcements from Firestore
          StreamBuilder<List<AnnouncementModel>>(
            stream: FirestoreService.announcementsStream(limit: 3),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No news available.');
              }
              final announcements = snapshot.data!;
              return Column(
                children: announcements.map((announcement) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.announcementDetail,
                            arguments: announcement,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isValidImageUrl(announcement.image))
                              CachedNetworkImage(
                                imageUrl: announcement.image!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 120,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 120,
                                width: double.infinity,
                                color: _getAnnouncementColor(announcement.category).withOpacity(0.1),
                                child: Center(
                                  child: Icon(
                                    _getAnnouncementIcon(announcement.category),
                                    size: 50,
                                    color: _getAnnouncementColor(announcement.category),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.content,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider appProvider) {
    final actions = [
      {'icon': Icons.receipt_long, 'label': 'Bills', 'route': AppRoutes.bills, 'color': Colors.blue},
      {'icon': Icons.build, 'label': 'Repairs', 'route': AppRoutes.repairs, 'color': Colors.orange},
      {'icon': Icons.inventory_2, 'label': 'Packages', 'route': AppRoutes.packages, 'color': Colors.purple},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appProvider.getLocalizedText('quick_access'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: actions.map((action) {
              return _buildQuickActionCard(
                context,
                action['icon'] as IconData,
                action['label'] as String,
                action['route'] as String,
                action['color'] as Color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    Color color,
  ) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.receipt, color: Colors.white),
              ),
              title: const Text('New Bill'),
              subtitle: const Text('Monthly maintenance fee is due'),
              trailing: const Text('1h ago'),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.local_shipping, color: Colors.white),
              ),
              title: const Text('Package Arrived'),
              subtitle: const Text('Your package is ready for pickup'),
              trailing: const Text('3h ago'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAnnouncementColor(String category) {
    switch (category) {
      case 'event':
        return Colors.purple;
      case 'maintenance':
        return Colors.orange;
      case 'notice':
        return Colors.blue;
      case 'facility':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getAnnouncementIcon(String category) {
    switch (category) {
      case 'event':
        return Icons.event;
      case 'maintenance':
        return Icons.build;
      case 'notice':
        return Icons.notifications;
      case 'facility':
        return Icons.pool;
      default:
        return Icons.info;
    }
  }
}

class _ServicesPage extends StatelessWidget {
  final AppProvider appProvider;

  const _ServicesPage({required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appProvider.getLocalizedText('services')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServiceCategory(
            context,
            'Financial',
            Icons.attach_money,
            [
              {'icon': Icons.receipt_long, 'label': appProvider.getLocalizedText('bills'), 'route': AppRoutes.bills},
            ],
            appProvider,
          ),
          const SizedBox(height: 16),
          _buildServiceCategory(
            context,
            'Property Management',
            Icons.home_work,
            [
              {'icon': Icons.build, 'label': appProvider.getLocalizedText('repairs'), 'route': AppRoutes.repairs},

            ],
            appProvider,
          ),
          const SizedBox(height: 16),
          _buildServiceCategory(
            context,
            'Community',
            Icons.groups,
            [
              {'icon': Icons.campaign, 'label': appProvider.getLocalizedText('announcements'), 'route': AppRoutes.announcements},
              // {'icon': Icons.pool, 'label': appProvider.getLocalizedText('amenities'), 'route': AppRoutes.amenities}, // TODO: 待实现
            ],
            appProvider,
          ),
          const SizedBox(height: 16),
          _buildServiceCategory(
            context,
            'Services',
            Icons.room_service,
            [
              // {'icon': Icons.people, 'label': appProvider.getLocalizedText('visitors'), 'route': AppRoutes.visitors}, // TODO: 待实现
              {'icon': Icons.inventory_2, 'label': appProvider.getLocalizedText('packages'), 'route': AppRoutes.packages},
            ],
            appProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategory(
    BuildContext context,
    String title,
    IconData icon,
    List<Map<String, dynamic>> services,
    AppProvider appProvider,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...services.map((service) {
              return ListTile(
                leading: Icon(service['icon'] as IconData),
                title: Text(service['label'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, service['route'] as String),
              );
            }),
          ],
        ),
      ),
    );
  }
}
class _ProfilePage extends StatelessWidget {
  final UserModel user;
  final AppProvider appProvider;

  const _ProfilePage({required this.user, required this.appProvider});

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

  // 辅助方法：构建玻璃风格的列表项 (适配白色背景)
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
          color: primaryColor.withOpacity(0.1), // 使用主题色的淡色背景
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryColor), // 使用主题色图标
      ),
      title: Text(
          title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500) // 深色文字
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.black54)) // 深色副标题
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.black38), // 深色图标
      onTap: onTap,
    );
  }

  // 辅助方法：构建信息行 (适配白色背景)
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor), // 使用主题色图标
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54, // 深色标签
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87, // 深色数值
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // 定义背景渐变 (与 Admin 页面保持一致，衬托白色玻璃)
    final Color bgGradientStart = const Color(0xFFF3F4F6);
    final Color bgGradientEnd = const Color(0xFFE5E7EB);

    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final currentUser = appProvider.currentUser ?? user;

        return Scaffold(
          extendBodyBehindAppBar: true, // 让背景延伸到 AppBar 后面
          appBar: AppBar(
            title: Text(
              appProvider.getLocalizedText('profile'),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent, // 透明背景
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  // 这里也可以加一个 Glass 风格的确认弹窗，逻辑参考 AdminHomeScreen
                  MockData.currentUser = null;
                  appProvider.updateUser(null as UserModel?);
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          ),
          body: Container(
            // 使用渐变背景，否则白色玻璃看不见
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
                            fontWeight: FontWeight.w800, // 更粗的字体
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

                  // Property Info (Glass Card)
                  GlassContainer(
                    // 移除 color 参数，使用默认 iOS 风格白
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            appProvider.getLocalizedText('property_information'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildInfoRow(context, Icons.home_rounded, appProvider.getLocalizedText('address'), currentUser.propertySimpleAddress),
                        const SizedBox(height: 12),
                        _buildInfoRow(context, Icons.phone_rounded, appProvider.getLocalizedText('phone'), currentUser.phoneNumber ?? 'Not set'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu Options (Glass Card)
                  GlassContainer(
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.symmetric(vertical: 8), // 列表式布局，垂直padding小一点
                    child: Column(
                      children: [
                        _buildGlassListTile(
                          context,
                          icon: Icons.edit_outlined,
                          title: appProvider.getLocalizedText('edit_profile'),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                        ),
                        _buildDivider(),
                        _buildGlassListTile(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: appProvider.getLocalizedText('change_password'),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                        ),
                        _buildDivider(),
                        _buildGlassListTile(
                          context,
                          icon: Icons.language_rounded,
                          title: appProvider.getLocalizedText('language'),
                          subtitle: _getLanguageName(context.locale.languageCode),
                          onTap: () => _showLanguageDialog(context),
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

                  // About (Glass Card)
                  GlassContainer(
                    opacity: 0.8,
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _buildGlassListTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          title: appProvider.getLocalizedText('help_support'),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                        ),
                        _buildDivider(),
                        _buildGlassListTile(
                          context,
                          icon: Icons.info_outline_rounded,
                          title: appProvider.getLocalizedText('about'),
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

  // 辅助方法：稍微优化分隔线，使其在玻璃上看起来更自然
  Widget _buildDivider() {
    return Divider(
        height: 1,
        color: Colors.grey.withOpacity(0.2),
        indent: 56, // 让分割线不贯穿图标
        endIndent: 20
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final supportedLocales = context.supportedLocales;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: supportedLocales.map((locale) {
              return ListTile(
                title: Text(_getLanguageName(locale.languageCode)),
                leading: Radio<String>(
                  value: locale.languageCode,
                  groupValue: context.locale.languageCode,
                  onChanged: (String? value) {
                    if (value != null) {
                      context.setLocale(Locale(value));
                      Navigator.of(context).pop();
                    }
                  },
                ),
                onTap: () {
                  context.setLocale(locale);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // 放在 _ProfilePage 类内部的底部

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ms':
        return 'Bahasa Melayu';
      default:
        return code;
    }
  }
}
