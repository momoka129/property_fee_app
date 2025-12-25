import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../providers/app_provider.dart';
import '../../widgets/glass_container.dart'; // 确保引入 GlassContainer

class ServicesTab extends StatelessWidget {
  final AppProvider appProvider;

  const ServicesTab({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    // 定义背景渐变 (与 Profile/Dashboard 保持一致)
    final Color bgGradientStart = const Color(0xFFF3F4F6);
    final Color bgGradientEnd = const Color(0xFFE5E7EB);

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
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: const Text(
                'Services',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24, // 稍微调小一点适配 Sliver
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(color: Colors.transparent),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildServiceSection(
                    context,
                    title: 'Financial',
                    services: [
                      {
                        'icon': Icons.receipt_long_rounded,
                        'label': 'Bills',
                        'subtitle': 'Pay maintenance & utilities',
                        'route': AppRoutes.bills,
                        'color': Colors.blue,
                      },
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildServiceSection(
                    context,
                    title: 'Property Management',
                    services: [
                      {
                        'icon': Icons.build_rounded,
                        'label': 'Repairs',
                        'subtitle': 'Report & track issues',
                        'route': AppRoutes.repairs,
                        'color': Colors.orange,
                      },
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildServiceSection(
                    context,
                    title: 'Community',
                    services: [
                      {
                        'icon': Icons.campaign_rounded,
                        'label': 'Announcements',
                        'subtitle': 'News & notices',
                        'route': AppRoutes.announcements,
                        'color': Colors.redAccent,
                      },
                      // 可以在这里取消注释以启用更多功能
                      // {
                      //   'icon': Icons.pool_rounded,
                      //   'label': 'Amenities',
                      //   'subtitle': 'Book facilities',
                      //   'route': AppRoutes.amenities, // 假设有这个路由
                      //   'color': Colors.teal,
                      // },
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildServiceSection(
                    context,
                    title: 'Logistics',
                    services: [
                      {
                        'icon': Icons.inventory_2_rounded,
                        'label': 'Packages',
                        'subtitle': 'My parcels & deliveries',
                        'route': AppRoutes.packages,
                        'color': Colors.purple,
                      },
                      // {
                      //   'icon': Icons.person_add_alt_1_rounded,
                      //   'label': 'Visitors',
                      //   'subtitle': 'Pre-register guests',
                      //   'route': AppRoutes.visitors, // 假设有这个路由
                      //   'color': Colors.indigo,
                      // },
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSection(
      BuildContext context, {
        required String title,
        required List<Map<String, dynamic>> services,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GlassContainer(
          opacity: 0.8,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              for (int i = 0; i < services.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: Colors.grey.withOpacity(0.15),
                    indent: 64, // 让分割线对齐文字
                    endIndent: 20,
                  ),
                _buildServiceTile(
                  context,
                  icon: services[i]['icon'] as IconData,
                  label: services[i]['label'] as String,
                  subtitle: services[i]['subtitle'] as String?,
                  route: services[i]['route'] as String,
                  color: services[i]['color'] as Color,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        String? subtitle,
        required String route,
        required Color color,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      )
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}