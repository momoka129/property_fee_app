import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // 引入 Provider
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart'; // 如果不再使用 MockData，可以逐步移除
import '../models/bill_model.dart';
import '../services/firestore_service.dart';
import '../widgets/bill_card.dart';
import '../routes.dart';
import '../providers/app_provider.dart'; // 引入 AppProvider 获取真实用户
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
    // 修改 1: Tab 数量改为 3 (Unpaid, Overdue, Paid)
    _tabController = TabController(length: 3, vsync: this);

    // 修改 2: 页面初始化时，触发后台检查逾期和罚金逻辑
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AppProvider>(context, listen: false).currentUser;
      if (user != null) {
        FirestoreService.checkAndProcessOverdueBills(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 优先使用 Provider 中的真实用户，如果未登录则回退或提示
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser ?? MockData.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bills & Payments')),
        body: const Center(child: Text('Please login first')),
      );
    }

    // 保持你原有的 StreamBuilder 结构，因为它包含了完善的错误处理
    return StreamBuilder<List<BillModel>>(
      // 这里获取所有账单，我们在内存中进行分类，这样可以复用你写好的错误处理 UI
      stream: FirestoreService.getUserBillsStream(currentUser.id),
      builder: (context, snapshot) {
        // --- 保持你原有的索引错误处理逻辑 (Index Error Handling) ---
        if (_showIndexError && _indexErrorUrl != null) {
          return _buildIndexErrorScreen();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bills & Payments')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          _checkAndHandleIndexError(snapshot.error);
          if (_indexErrorUrl != null) {
            // 如果检测到是索引错误，显示 Loading 或空，等待 addPostFrameCallback 刷新 UI
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return _buildGenericErrorScreen(snapshot.error);
        }
        // -------------------------------------------------------

        final bills = snapshot.data ?? [];

        // 修改 3: 数据分类 (增加 Overdue)
        // 注意：Unpaid 列表排除掉状态已经是 'overdue' 的
        final unpaidBills = bills.where((b) => b.status == 'unpaid').toList();
        final overdueBills = bills.where((b) => b.status == 'overdue').toList();
        final paidBills = bills.where((b) => b.status == 'paid').toList();

        // 计算总欠款：Unpaid + Overdue (含罚金)
        final double totalUnpaidAmount = unpaidBills.fold(0, (sum, b) => sum + b.amount);
        final double totalOverdueAmount = overdueBills.fold(0, (sum, b) => sum + b.totalAmount); // totalAmount 包含罚金
        final double totalOutstanding = totalUnpaidAmount + totalOverdueAmount;

        // 合并所有需要支付的账单（用于 Pay All）
        final allPayableBills = [...overdueBills, ...unpaidBills];

        if (bills.isEmpty) {
          return _buildEmptyState();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bills & Payments'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.deepOrange, // 选中颜色
              indicatorColor: Colors.deepOrange,
              tabs: [
                Tab(text: 'Unpaid (${unpaidBills.length})'),
                Tab(text: 'Overdue (${overdueBills.length})'), // 新增 Tab
                Tab(text: 'Paid (${paidBills.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // 修改 4: 顶部总欠款显示逻辑
              if (totalOutstanding > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border(bottom: BorderSide(color: Colors.orange.shade100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total Outstanding',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange.shade800
                            ),
                          ),
                          if (totalOverdueAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Includes Penalty',
                                  style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RM ${totalOutstanding.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              _showPayAllDialog(allPayableBills, totalOutstanding);
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Pay All'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                            ),
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
                    _buildBillList(unpaidBills, type: 'unpaid'),
                    _buildBillList(overdueBills, type: 'overdue'), // 新增列表
                    _buildBillList(paidBills, type: 'paid'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 修改 5: 构建列表方法，增加 type 参数处理不同样式
  Widget _buildBillList(List<BillModel> bills, {required String type}) {
    if (bills.isEmpty) {
      IconData icon;
      String text;
      switch (type) {
        case 'overdue':
          icon = Icons.check_circle_outline; // 没有逾期是好事
          text = 'No overdue bills';
          break;
        case 'paid':
          icon = Icons.history;
          text = 'No payment history';
          break;
        default:
          icon = Icons.receipt_long_outlined;
          text = 'No unpaid bills';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
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
        final isOverdue = type == 'overdue';

        // 格式化金额显示：如果是逾期，显示总金额（含罚金）
        String amountText = 'RM ${bill.totalAmount.toStringAsFixed(2)}';
        // 如果有罚金，可以在 UI 上额外提示，这里简单通过金额展示

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
            amount: amountText,
            due: _formatDueDate(bill.dueDate),
            icon: _getCategoryIcon(bill.category),
            isOverdue: isOverdue || bill.isOverdue, // 确保红色高亮
          ),
        );
      },
    );
  }

  // --- 辅助方法 ---

  void _checkAndHandleIndexError(Object? err) {
    String? indexUrl;
    final msg = err.toString();
    final match = RegExp(r'https?:\\/\\/console\\.firebase\\.google\\.com[^\\s)]+').firstMatch(msg);
    if (match != null) {
      indexUrl = match.group(0);
    }

    if (indexUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _indexErrorUrl = indexUrl;
            _showIndexError = true;
          });
        }
      });
    }
  }

  // 抽取出来的错误页面组件
  Widget _buildIndexErrorScreen() {
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open link')),
                      );
                    }
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

  Widget _buildGenericErrorScreen(Object? error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bills & Payments')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error loading bills: $error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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

  void _showPayAllDialog(List<BillModel> bills, double totalAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay All Bills'),
        content: Text('Are you sure you want to pay all ${bills.length} bills totaling RM ${totalAmount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.payment,
                arguments: {
                  'bill': bills.first,
                  'bills': bills,
                },
              ).then((_) {
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