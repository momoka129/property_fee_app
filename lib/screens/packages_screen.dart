import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/url_utils.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/package_model.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  @override
  Widget build(BuildContext context) {
    final readyPackages = MockData.packages.where((p) => p.status == 'ready_for_pickup').toList();
    final collectedPackages = MockData.packages.where((p) => p.status == 'collected').toList();

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
  }

  Widget _buildPackageList(BuildContext context, List packages, bool isReady) {
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

  void _showPackageDetails(BuildContext context, package) {
    showModalBottomSheet(
      context: context,
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
                  onPressed: () {
                    // 更新包裹状态
                    final packageIndex = MockData.packages.indexWhere((p) => p.id == package.id);
                    if (packageIndex != -1) {
                      final updatedPackage = PackageModel(
                        id: package.id,
                        userId: package.userId,
                        trackingNumber: package.trackingNumber,
                        courier: package.courier,
                        description: package.description,
                        status: 'collected',
                        arrivedAt: package.arrivedAt,
                        collectedAt: DateTime.now(),
                        location: package.location,
                        image: package.image,
                        notes: package.notes,
                      );
                      MockData.packages[packageIndex] = updatedPackage;
                    }

                    Navigator.pop(context);
                    setState(() {}); // 刷新页面
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Package marked as collected'),
                        backgroundColor: Colors.green,
                      ),
                    );
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

