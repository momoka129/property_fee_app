import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/announcement_model.dart';
import '../../models/package_model.dart';
import '../../models/bill_model.dart';
import '../../services/firestore_service.dart';
import '../../routes.dart';
import '../../providers/app_provider.dart';
import '../../utils/url_utils.dart';
import '../../utils/bill_message.dart';
import '../../widgets/glass_container.dart'; // 确保引入 GlassContainer

class DashboardTab extends StatefulWidget {
  final UserModel user;
  final AppProvider appProvider;

  const DashboardTab({
    super.key,
    required this.user,
    required this.appProvider
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirestoreService.checkAndProcessOverdueBills(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final appProvider = widget.appProvider;

    // 定义背景渐变 (与 ProfileTab 保持一致)
    final Color bgGradientStart = const Color(0xFFF3F4F6);
    final Color bgGradientEnd = const Color(0xFFE5E7EB);
    // primaryColor removed (unused)

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgGradientStart, bgGradientEnd],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent, // 透明背景
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi, ${user.name.split(' ').first} 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800, // 更粗的字体，iOS风格
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Unit ${user.propertySimpleAddress}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              StreamBuilder<int>(
                stream: FirestoreService.getUnreadNotificationCountStream(user.id),
                builder: (context, snapshot) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.notifications);
                          },
                        ),
                      ),
                      // notification badge removed (no visual red dot)
                    ],
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Quick Stats Area
                  _buildQuickStats(context, appProvider),
                  const SizedBox(height: 24),

                  // Urgent Notifications
                  _buildUrgentNotifications(context, appProvider),

                  // Quick Actions (Moved up for better UX flow)
                  _buildSectionHeader(context, 'Quick Access'),
                  _buildQuickActions(context, appProvider),
                  const SizedBox(height: 24),

                  // Recent Announcements
                  _buildRecentAnnouncements(context, appProvider),

                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppProvider appProvider) {
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getUserBillsStream(widget.user.id),
      builder: (context, billsSnapshot) {
        if (billsSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final primaryBills = billsSnapshot.data ?? [];
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

                // 包含需要支付的账单：未付和逾期（逾期使用 totalAmount 包含罚金）
                final payableBills = bills.where((b) => b.status == 'unpaid' || b.status == 'overdue').toList();
                final payableTotal = payableBills.fold<double>(0, (sum, b) => sum + (b.isOverdue ? b.totalAmount : b.amount));
                final readyPackages = packages.where((p) => p.status == 'ready_for_pickup').toList();

                return Row(
                  children: [
                    Expanded(
                      child: _buildGlassStatCard(
                        context,
                        // Display label in English
                        'Amount Due',
                        finalBillsSnapshot.connectionState == ConnectionState.waiting
                            ? '...'
                            : 'RM ${payableTotal.toStringAsFixed(0)}',
                        Icons.receipt_long_rounded,
                        Colors.orange,
                        payableBills.isNotEmpty,
                        onTap: () async {
                          await Navigator.pushNamed(context, AppRoutes.bills);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing
                    Expanded(
                      child: _buildGlassStatCard(
                        context,
                        'Packages',
                        packagesSnapshot.connectionState == ConnectionState.waiting
                            ? '...'
                            : '${readyPackages.length}',
                        Icons.inventory_2_rounded,
                        Colors.blue,
                        readyPackages.isNotEmpty,
                        onTap: () async {
                          await Navigator.pushNamed(context, AppRoutes.packages);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGlassStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color accentColor,
      bool hasNotification, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        opacity: 0.7,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                // stat card notification dot removed
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
        // Overdue 判断：显式标记为 'overdue' 的，或者仍为 'unpaid' 且 dueDate 在今天之前的
        final overdueBills = bills.where((b) =>
            b.status == 'overdue' ||
            (b.status == 'unpaid' && b.dueDate.isBefore(DateTime.now()))
        ).toList();

        // Compose concise Chinese message using utility
        final int totalToPayCount = unpaidBills.length + overdueBills.length;
        final String billsMessage = formatConciseBillsMessage(
          unpaid: unpaidBills.length,
          overdue: overdueBills.length,
          totalToPay: totalToPayCount,
        );

        // Always show the bulletin (non-clickable). Display counts and a message.
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _buildSectionHeader(context, 'Needs Attention'),
              GlassContainer(
                opacity: 0.8,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  ),
                  title: const Text(
                    'Bills',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        billsMessage,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      // Message priority: if no bills at all -> positive message,
                      // else if there are overdue bills -> warning message,
                      // otherwise show a neutral reminder about unpaid bills.
                      if (unpaidBills.isEmpty && overdueBills.isEmpty)
                        const Text(
                          'Very good, you have no bills to pay.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        )
                      else if (overdueBills.isNotEmpty)
                        const Text(
                          'Not great, please pay as soon as possible.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        )
                      else
                        Text(
                          'You have ${unpaidBills.length} unpaid bill(s).',
                          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  // Make it non-clickable: remove trailing chevron and onTap
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentAnnouncements(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            context,
            'Community News',
            onSeeAll: () => Navigator.pushNamed(context, AppRoutes.announcements)
        ),

        StreamBuilder<List<AnnouncementModel>>(
          stream: FirestoreService.announcementsStream(limit: 10), // 获取更多公告以便筛选置顶的
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return GlassContainer(
                opacity: 0.6,
                padding: const EdgeInsets.all(16),
                child: const Center(child: Text('No news available.')),
              );
            }

            // 排序：置顶的公告排在前面，按发布时间倒序
            final announcements = snapshot.data!
              ..sort((a, b) {
                // 置顶的优先级最高
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                // 同等置顶状态下，按发布时间倒序
                return b.publishedAt.compareTo(a.publishedAt);
              });

            // 只显示前3个（优先显示置顶的）
            final displayAnnouncements = announcements.take(3).toList();

            return Column(
              children: displayAnnouncements.map((announcement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.announcementDetail,
                        arguments: announcement,
                      );
                    },
                    child: GlassContainer(
                      opacity: 0.8,
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.zero, // Important to let image fill
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section
                          if (isValidImageUrl(announcement.image))
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: CachedNetworkImage(
                                imageUrl: announcement.image!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 140,
                                  color: Colors.grey.withOpacity(0.1),
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _getAnnouncementColor(announcement.category).withOpacity(0.1),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Center(
                                child: Icon(
                                  _getAnnouncementIcon(announcement.category),
                                  size: 40,
                                  color: _getAnnouncementColor(announcement.category),
                                ),
                              ),
                            ),

                          // Content Section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getAnnouncementColor(announcement.category).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        announcement.category.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getAnnouncementColor(announcement.category),
                                        ),
                                      ),
                                    ),
                                    if (announcement.isPinned) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.push_pin,
                                          size: 12,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  announcement.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  announcement.content,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.4,
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
    );
  }

  Widget _buildQuickActions(BuildContext context, AppProvider appProvider) {
    final actions = [
      {'icon': Icons.receipt_long_rounded, 'label': 'Bills', 'route': AppRoutes.bills, 'color': Colors.blue},
      {'icon': Icons.build_rounded, 'label': 'Repairs', 'route': AppRoutes.repairs, 'color': Colors.orange},
      {'icon': Icons.inventory_2_rounded, 'label': 'Packages', 'route': AppRoutes.packages, 'color': Colors.purple},
      // 可以在这里加更多功能，比如 Visitors
    ];

    return GlassContainer(
      opacity: 0.7,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return _buildQuickActionItem(
            context,
            action['icon'] as IconData,
            action['label'] as String,
            action['route'] as String,
            action['color'] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionItem(
      BuildContext context,
      IconData icon,
      String label,
      String route,
      Color color,
      ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAnnouncementColor(String category) {
    switch (category.toLowerCase()) {
      case 'event': return Colors.purple;
      case 'maintenance': return Colors.orange;
      case 'notice': return Colors.blue;
      case 'facility': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getAnnouncementIcon(String category) {
    switch (category.toLowerCase()) {
      case 'event': return Icons.event;
      case 'maintenance': return Icons.build;
      case 'notice': return Icons.campaign;
      case 'facility': return Icons.pool;
      default: return Icons.info_outline;
    }
  }
}