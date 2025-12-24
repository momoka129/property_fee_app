import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../models/bill_model.dart';
import '../services/firestore_service.dart';
import '../widgets/bill_card.dart';
import '../routes.dart';
import 'bill_detail.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _indexErrorUrl;
  bool _showIndexError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = MockData.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bills & Payments')),
        body: const Center(child: Text('Please login first')),
      );
    }

    return StreamBuilder<List<BillModel>>(
      stream: FirestoreService.getUserBillsStream(currentUser.id),
      builder: (context, snapshot) {
        // If we have been instructed to show the index-required error persistently,
        // render that UI immediately so it doesn't flicker away when the stream emits
        // transient empty values.
        if (_showIndexError && _indexErrorUrl != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error loading bills: Firestore requires a composite index for this query.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () async {
                        final uri = Uri.parse(_indexErrorUrl!);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open link')),
                          );
                        }
                      },
                      child: const Text('Create required Firestore index'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // allow retry / dismiss
                            setState(() {
                              _showIndexError = false;
                              _indexErrorUrl = null;
                            });
                          },
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            // Clear and force rebuild to re-subscribe to stream
                            setState(() {
                              _showIndexError = false;
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // If the error indicates a missing index, persistently show the index UI
          // (so the screen doesn't flash away when the stream later emits an empty list).
          final err = snapshot.error;
          String? indexUrl;
          if (err is FirebaseException) {
            final msg = err.message ?? '';
            final match = RegExp(r'https?:\\/\\/console\\.firebase\\.google\\.com[^\\s)]+').firstMatch(msg);
            if (match != null) {
              indexUrl = match.group(0);
            }
          } else if (err is Exception) {
            final msg = err.toString();
            final match = RegExp(r'https?:\\/\\/console\\.firebase\\.google\\.com[^\\s)]+').firstMatch(msg);
            if (match != null) {
              indexUrl = match.group(0);
            }
          }

          if (indexUrl != null) {
            // schedule a state update after this build to show the persistent error UI
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _indexErrorUrl = indexUrl;
                  _showIndexError = true;
                });
              }
            });
            // Meanwhile render a neutral loading/error placeholder so build returns quickly.
            return Scaffold(
              appBar: AppBar(title: const Text('Bills & Payments')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error loading bills: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A required Firestore index is missing; opening the index creation link is recommended.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // For non-index errors, show the existing error UI once.
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error loading bills: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Primary result by userId
        final bills = snapshot.data ?? [];

        // Process bills data
        final unpaidBills = bills.where((b) => b.status == 'unpaid').toList();
        final paidBills = bills.where((b) => b.status == 'paid').toList();
        final unpaidTotal = unpaidBills.fold<double>(0, (sum, b) => sum + b.amount);

        // If no bills at all, show simple empty state
        if (bills.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bills found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your bills will appear here once they are created',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bills & Payments'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Unpaid (${unpaidBills.length})'),
                Tab(text: 'Paid (${paidBills.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              if (unpaidTotal > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.orange.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Outstanding',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RM ${unpaidTotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                          ),
                          FilledButton(
                            onPressed: () {
                              _showPayAllDialog(unpaidBills);
                            },
                            child: const Text('Pay All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBillList(unpaidBills, true),
                    _buildBillList(paidBills, false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillList(List<BillModel> bills, bool isUnpaid) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnpaid ? Icons.check_circle_outline : Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isUnpaid ? 'No unpaid bills' : 'No payment history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BillDetailScreen(bill: bill),
              ),
            );
          },
          child: BillCard(
            title: bill.title,
            amount: 'RM ${bill.amount.toStringAsFixed(2)}',
            due: _formatDueDate(bill.dueDate),
            icon: _getCategoryIcon(bill.category),
            isOverdue: bill.isOverdue,
          ),
        );
      },
    );
  }

  String _formatDueDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'maintenance':
        return Icons.build_outlined;
      case 'parking':
        return Icons.local_parking_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'electricity':
        return Icons.bolt_outlined;
      case 'gas':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  void _showPayAllDialog(List<BillModel> bills) {
    final total = bills.fold<double>(0, (sum, b) => sum + b.amount);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay All Bills'),
        content: Text('Are you sure you want to pay all ${bills.length} bills totaling RM ${total.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // 跳转到支付页面（批量支付）
              Navigator.pushNamed(
                context,
                AppRoutes.payment,
                arguments: {
                  'bill': bills.first, // 使用第一个账单作为主要账单
                  'bills': bills, // 传递所有账单
                },
              ).then((_) {
                // 支付完成后刷新页面
                if (mounted) {
                  setState(() {});
                }
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
