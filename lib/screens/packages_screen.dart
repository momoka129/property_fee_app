import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // 需要导入 provider
import '../utils/url_utils.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';
import '../services/firestore_service.dart'; // 导入 Firestore 服务
import '../providers/app_provider.dart'; // 导入 AppProvider 获取用户信息

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  @override
  Widget build(BuildContext context) {
    // 获取当前用户
    final appProvider = Provider.of<AppProvider>(context);
    final user = appProvider.currentUser;

    // 如果用户未登录，显示提示
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Package Management')),
        body: const Center(child: Text('Please login to view packages')),
      );
    }

    // 使用 StreamBuilder 监听 Firebase 数据
    return StreamBuilder<List<PackageModel>>(
      stream: FirestoreService.getUserPackagesStream(user.id),
      builder: (context, snapshot) {
        // 加载状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Package Management')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // 错误处理
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Package Management')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // 获取数据并分类
        final packages = snapshot.data ?? [];
        final readyPackages = packages.where((p) => p.status == 'ready_for_pickup').toList();
        final collectedPackages = packages.where((p) => p.status == 'collected').toList();

        // 构建 UI (TabController 包裹 Scaffold)
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Package Management'),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Ready (${readyPackages.length})'),
                  Tab(text: 'Collected (${collectedPackages.length})'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildPackageList(context, readyPackages, true),
                _buildPackageList(context, collectedPackages, false),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackageList(BuildContext context, List<PackageModel> packages, bool isReady) {
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isReady ? 'No packages waiting' : 'No collection history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          child: InkWell(
            onTap: () => _showPackageDetails(context, package),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (isValidImageUrl(package.image))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: package.image!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2, size: 30),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.courier,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          package.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tracking: ${package.trackingNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              package.location,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.access_time, color: Colors.green, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            '${package.waitingDays}d',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPackageDetails(BuildContext context, PackageModel package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许弹窗在需要时占据更多高度
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (isValidImageUrl(package.image)) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: package.image!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Courier', package.courier),
            _buildDetailRow('Tracking Number', package.trackingNumber),
            _buildDetailRow('Description', package.description),
            _buildDetailRow('Location', package.location),
            _buildDetailRow('Arrived', DateFormat('MMM dd, yyyy HH:mm').format(package.arrivedAt)),
            _buildDetailRow('Status', package.statusDisplay),
            if (package.status == 'ready_for_pickup') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    // 更新包裹状态
                    try {
                      await FirestoreService.updatePackageStatus(
                        package.id,
                        'collected',
                        collectedAt: DateTime.now(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Package marked as collected'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Mark as Collected'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}