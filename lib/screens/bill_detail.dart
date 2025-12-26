import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../data/mock_data.dart';
import '../routes.dart';
import '../widgets/glass_container.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 状态标签
                  _buildStatusChip(context),
                  const SizedBox(height: 24),

                  // 金额卡片
                  _buildAmountCard(context),
                  const SizedBox(height: 24),

                  // 账单信息
                  _buildInfoSection(context),
                  const SizedBox(height: 24),

                  // 描述
                  if (bill.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bill.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 支付历史
                  if (bill.status == 'paid' && bill.paymentId != null) ...[
                    _buildPaymentInfo(context),
                  ],
                ],
              ),
            ),
          ),

          // 底部支付按钮
          // Allow payment for both unpaid and overdue bills (overdue should be payable like unpaid)
          if (bill.status == 'unpaid' || bill.isOverdue) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => _onPayNow(context),
                    child: const Text('Pay Now'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final bill = widget.bill;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (bill.status == 'paid') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (bill.isOverdue) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.error;
    } else {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            bill.statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    final bill = widget.bill;
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 12,
      opacity: 0.75,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            // If the bill is overdue show the total amount (principal + penalty), otherwise show base amount
            'RM ${(bill.isOverdue ? bill.totalAmount : bill.amount).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final bill = widget.bill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(context, 'Bill Title', bill.title),
        _buildInfoRow(context, 'Category', _getCategoryName(bill.category)),
        _buildInfoRow(
          context,
          'Billing Date',
          _formatDate(bill.billingDate),
        ),
        _buildInfoRow(
          context,
          'Due Date',
          _formatDate(bill.dueDate),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    final bill = widget.bill;
    // 从MockData中查找支付记录
    final payment = MockData.payments.where((p) => p.billId == bill.id).firstOrNull;
    
    if (payment == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: BorderRadius.circular(12),
          blur: 10,
          opacity: 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'Payment Date',
                DateFormat('MMM dd, yyyy').format(payment.paymentDate),
              ),
              _buildInfoRow(
                context,
                'Payment Method',
                payment.paymentMethodDisplay,
              ),
              _buildInfoRow(
                context,
                'Transaction ID',
                payment.transactionId,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onPayNow(BuildContext context) {
    final bill = widget.bill;
    // 跳转到支付页面
    Navigator.pushNamed(
      context,
      AppRoutes.payment,
      arguments: bill,
    ).then((_) {
      // 支付完成后刷新页面
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'maintenance':
        return 'Maintenance Fee';
      case 'parking':
        return 'Parking Fee';
      case 'water':
        return 'Water Bill';
      case 'electricity':
        return 'Electricity Bill';
      case 'gas':
        return 'Gas Bill';
      default:
        return 'Other';
    }
  }
}

