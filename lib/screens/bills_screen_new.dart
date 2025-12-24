import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final bills = snapshot.data ?? [];
        final unpaidBills = bills.where((b) => b.status == 'unpaid').toList();
        final paidBills = bills.where((b) => b.status == 'paid').toList();
        final unpaidTotal = unpaidBills.fold<double>(0, (sum, b) => sum + b.amount);

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


