import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/bill_model.dart';
import '../models/repair_model.dart';
import '../models/package_model.dart';
import '../routes.dart';
import 'edit_profile_screen.dart';
import '../widgets/glass_container.dart'; // 引入 GlassContainer

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // 现代配色方案
  final Color bgGradientStart = const Color(0xFFF3F4F6);
  final Color bgGradientEnd = const Color(0xFFE5E7EB);
  final Color cardColor = Colors.white;
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color secondaryColor = const Color(0xFF818CF8);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color errorColor = const Color(0xFFEF4444);

  final BorderRadius kCardRadius = BorderRadius.circular(24);
  final List<BoxShadow> kCardShadow = [
    BoxShadow(
      color: const Color(0xFF1F2937).withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKPIGrid(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Financial Overview"),
                      const SizedBox(height: 12),
                      _buildRevenueChart(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Bill Status"),
                                const SizedBox(height: 12),
                                _buildBillStatusPieChart(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Repairs"),
                                const SizedBox(height: 12),
                                _buildRepairBarChart(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Quick Actions"),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),
                      const SizedBox(height: 30),
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/images/avatar_default.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  // --- 使用 GlassContainer 的登出弹窗 ---
  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          // 关键：背景透明，让 GlassContainer 发挥作用
          barrierColor: Colors.black.withOpacity(0.3), // 背景遮罩稍微淡一点，突出玻璃
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(20),
            child: GlassContainer(
              // 不透明度可以稍微高一点，保证不发灰
              opacity: 0.85,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.logout_rounded, size: 32, color: errorColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Are you sure you want to sign out?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]), // 字体深一点
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: errorColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0, // 去掉按钮阴影，风格更扁平
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Sign Out"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
          }
        }
      },
      borderRadius: kCardRadius,
      child: Container(
        // ... 原有按钮样式保持不变
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: kCardRadius,
          boxShadow: kCardShadow,
          border: Border.all(color: errorColor.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: errorColor),
            const SizedBox(width: 10),
            Text(
              "Sign Out",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- KPIS & Charts ---
  Widget _buildKPIGrid() {
    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getAllBillsStream(),
      builder: (context, billSnap) {
        return StreamBuilder<List<RepairModel>>(
          stream: FirestoreService.getAllRepairsStream(),
          builder: (context, repairSnap) {
            return StreamBuilder<List<PackageModel>>(
              stream: FirestoreService.getAllPackagesStream(),
              builder: (context, packageSnap) {
                final bills = billSnap.data ?? [];
                final repairs = repairSnap.data ?? [];
                final packages = packageSnap.data ?? [];

                final totalRevenue = bills
                    .where((b) => b.status == 'paid')
                    .fold(0.0, (sum, b) => sum + b.amount);

                final overdueCount = bills.where((b) => b.status == 'overdue').length;
                final pendingRepairs = repairs.where((r) => r.status == 'pending').length;
                final activePackages = packages.where((p) => p.status != 'collected').length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildStatCard(title: 'Total Revenue', value: 'RM ${totalRevenue.toStringAsFixed(0)}', icon: Icons.monetization_on_outlined, themeColor: successColor, width: width, isMain: true),
                        _buildStatCard(title: 'Overdue Bills', value: '$overdueCount', icon: Icons.error_outline, themeColor: errorColor, width: width),
                        _buildStatCard(title: 'Pending Repairs', value: '$pendingRepairs', icon: Icons.home_repair_service_outlined, themeColor: warningColor, width: width),
                        _buildStatCard(title: 'Packages', value: '$activePackages', icon: Icons.inventory_2_outlined, themeColor: primaryColor, width: width),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color themeColor, required double width, bool isMain = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isMain ? themeColor : cardColor,
        borderRadius: kCardRadius,
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMain ? Colors.white.withOpacity(0.2) : themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isMain ? Colors.white : themeColor, size: 20),
              ),
              if (!isMain) Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isMain ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isMain ? Colors.white.withOpacity(0.8) : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(20, 25, 25, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: kCardRadius,
        boxShadow: kCardShadow,
      ),
      child: StreamBuilder<List<BillModel>>(
        stream: FirestoreService.getAllBillsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bills = snapshot.data!;
          final now = DateTime.now();
          List<FlSpot> spots = [];
          for (int i = 5; i >= 0; i--) {
            final monthStart = DateTime(now.year, now.month - i, 1);
            final monthEnd = DateTime(now.year, now.month - i + 1, 0);
            final monthlyRevenue = bills
                .where((b) => b.status == 'paid' && b.billingDate.isAfter(monthStart) && b.billingDate.isBefore(monthEnd))
                .fold(0.0, (sum, b) => sum + b.amount);
            spots.add(FlSpot((5-i).toDouble(), monthlyRevenue));
          }
          double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
          if (maxY == 0) maxY = 100;

          return LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime(now.year, now.month - (5 - value.toInt()), 1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(DateFormat('MMM').format(date), style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                      );
                    },
                    interval: 1,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: 5, minY: 0, maxY: maxY * 1.25,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: primaryColor);
                      }
                  ),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), primaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem('RM ${spot.y.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillStatusPieChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: kCardRadius, boxShadow: kCardShadow),
      child: StreamBuilder<List<BillModel>>(
        stream: FirestoreService.getAllBillsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bills = snapshot.data!;
          final paid = bills.where((b) => b.status == 'paid').length;
          final unpaid = bills.where((b) => b.status == 'unpaid').length;
          final overdue = bills.where((b) => b.status == 'overdue').length;
          if (bills.isEmpty) return Center(child: Text("No Data", style: TextStyle(color: Colors.grey[400])));

          return Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3, centerSpaceRadius: 35,
                  sections: [
                    _buildPieSection(paid.toDouble(), successColor),
                    _buildPieSection(unpaid.toDouble(), warningColor),
                    _buildPieSection(overdue.toDouble(), errorColor),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${bills.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Text("Total", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  PieChartSectionData _buildPieSection(double val, Color color) {
    return PieChartSectionData(value: val, color: color, radius: 18, showTitle: false);
  }

  Widget _buildRepairBarChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      decoration: BoxDecoration(color: cardColor, borderRadius: kCardRadius, boxShadow: kCardShadow),
      child: StreamBuilder<List<RepairModel>>(
        stream: FirestoreService.getAllRepairsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final repairs = snapshot.data!;
          final pending = repairs.where((r) => r.status == 'pending').length.toDouble();
          final progress = repairs.where((r) => r.status == 'in_progress').length.toDouble();
          final completed = repairs.where((r) => r.status == 'completed').length.toDouble();
          double maxY = [pending, progress, completed].reduce((a, b) => a > b ? a : b);
          if (maxY == 0) maxY = 5;

          return BarChart(
            BarChartData(
              barGroups: [
                _makeBarGroup(0, pending, warningColor),
                _makeBarGroup(1, progress, primaryColor),
                _makeBarGroup(2, completed, successColor),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    const style = TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold);
                    switch (value.toInt()) {
                      case 0: return const Padding(padding: EdgeInsets.only(top: 6), child: Text('Wait', style: style));
                      case 1: return const Padding(padding: EdgeInsets.only(top: 6), child: Text('WIP', style: style));
                      case 2: return const Padding(padding: EdgeInsets.only(top: 6), child: Text('Done', style: style));
                      default: return const Text('');
                    }
                  }),
                ),
              ),
              borderData: FlBorderData(show: false), gridData: FlGridData(show: false), maxY: maxY * 1.2,
            ),
          );
        },
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y, color: color, width: 12, borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: y == 0 ? 5 : y * 1.2, color: const Color(0xFFF3F4F6)),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.receipt_long_rounded, 'label': 'Bills', 'route': AppRoutes.adminBills, 'color': const Color(0xFF6366F1)},
      {'icon': Icons.handyman_rounded, 'label': 'Repairs', 'route': AppRoutes.adminRepairs, 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.inventory_2_rounded, 'label': 'Parcels', 'route': AppRoutes.adminPackages, 'color': const Color(0xFF10B981)},
      {'icon': Icons.campaign_rounded, 'label': 'News', 'route': AppRoutes.adminAnnouncements, 'color': const Color(0xFFEC4899)},
      {'icon': Icons.local_parking_rounded, 'label': 'Parking', 'route': AppRoutes.adminParking, 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.people_rounded, 'label': 'Users', 'route': AppRoutes.adminHome, 'color': const Color(0xFF8B5CF6)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final color = action['color'] as Color;
        return InkWell(
          onTap: () {
            if (action['label'] == 'Users') { } else { Navigator.pushNamed(context, action['route'] as String); }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 55, width: 55,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
                child: Icon(action['icon'] as IconData, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(action['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}