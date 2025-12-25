import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // 如果不需要校验 Auth 可以注释
import '../models/bill_model.dart';
import '../widgets/classical_dialog.dart';

class PaymentScreen extends StatefulWidget {
  final BillModel bill;
  final List<BillModel>? bills;

  const PaymentScreen({
    super.key,
    required this.bill,
    this.bills,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  List<BillModel> get _targetBills {
    if (widget.bills != null && widget.bills!.isNotEmpty) {
      return widget.bills!;
    }
    return [widget.bill];
  }

  double get _totalAmountToPay {
    return _targetBills.fold(0.0, (sum, b) {
      return sum + (b.isOverdue ? b.totalAmount : b.amount);
    });
  }

  /// 🎓 FYP 专用：模拟支付逻辑
  /// 不需要 Stripe，不需要 RevenueCat，直接模拟成功
  Future<void> _handleMockPayment() async {
    setState(() => _isLoading = true);

    // 1. 模拟网络请求延迟 (2秒)
    // 让用户感觉正在处理...
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. (可选) 这里可以加入随机失败，演示错误处理
    // if (DateTime.now().second % 10 == 0) { // 10% 概率失败
    //   _showErrorDialog("Simulated bank error. Please try again.");
    //   setState(() => _isLoading = false);
    //   return;
    // }

    // 3. 直接调用成功逻辑
    await _onPaymentSuccess();
  }

  Future<void> _onPaymentSuccess() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 批量更新所有涉及账单的状态
      for (var bill in _targetBills) {
        final docRef = FirebaseFirestore.instance.collection('bills').doc(bill.id);
        batch.update(docRef, {
          'status': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
          'paymentMethod': 'mock_payment', // 标记为模拟支付
        });
      }

      await batch.commit();

      setState(() => _isLoading = false);

      if (!mounted) return;

      // 弹出成功的雅致弹窗
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ClassicalDialog(
          title: 'Payment Successful',
          content:
          'Payment has been processed successfully.\n'
              'Total: RM ${_totalAmountToPay.toStringAsFixed(2)}\n'
              'Thank you for your payment.',
          confirmText: 'Done',
          onConfirm: () {
            Navigator.of(context).pop(); // 关弹窗
            Navigator.of(context).pop(); // 退出支付页面
          },
        ),
      );
    } catch (e) {
      print("Error updating bill status: $e");
      _showErrorDialog("Database error: $e");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => ClassicalDialog(
        title: 'Payment Failed',
        content: message,
        confirmText: 'OK',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMultiple = _targetBills.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (!isMultiple) ...[
              _buildDetailRow('Title', widget.bill.title),
              _buildDetailRow('Date', widget.bill.billingDate.toString().split(' ')[0]),
            ] else ...[
              _buildDetailRow('Total Bills', '${_targetBills.length} items'),
              const SizedBox(height: 8),
              Container(
                height: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _targetBills.length,
                  itemBuilder: (context, index) {
                    final b = _targetBills[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${b.title} (RM ${(b.isOverdue ? b.totalAmount : b.amount).toStringAsFixed(2)})',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ],

            const Divider(height: 32),
            _buildDetailRow(
              'Total Amount',
              'RM ${_totalAmountToPay.toStringAsFixed(2)}',
              isBold: true,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                // 这里的 onPressed 改为调用 _handleMockPayment
                onPressed: _isLoading ? null : _handleMockPayment,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isLoading ? 'Processing...' : 'Confirm Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 20 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}