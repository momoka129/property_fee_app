import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import '../data/mock_data.dart';
import '../services/firestore_service.dart';
import '../routes.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentScreen extends StatefulWidget {
  final BillModel bill;
  final List<BillModel>? bills; // 用于批量支付

  const PaymentScreen({
    super.key,
    required this.bill,
    this.bills,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  String? _processingStatus;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'wechat',
      'name': 'WeChat Pay',
      'icon': Icons.chat_bubble,
      'color': Colors.green,
      'description': 'Scan QR code to pay',
    },
    {
      'id': 'alipay',
      'name': 'Alipay',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'description': 'Pay with Alipay account',
    },
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'color': Colors.orange,
      'description': 'Transfer to bank account',
    },
  ];

  double get _totalAmount {
    if (widget.bills != null) {
      return widget.bills!.fold<double>(0, (sum, b) => sum + b.amount);
    }
    return widget.bill.amount;
  }

  @override
  Widget build(BuildContext context) {
    final isMultiple = widget.bills != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMultiple ? 'pay_all_bills'.tr() : 'payment'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 账单信息卡片
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMultiple ? 'bills_summary'.tr() : 'bill_details'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (isMultiple) ...[
                      Text(
                        '${'total_bills'.tr()}: ${widget.bills!.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Text(
                        widget.bill.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.bill.description.isNotEmpty)
                        Text(
                          widget.bill.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total_amount'.tr(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'RM ${_totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 支付方式选择
            Text(
              'select_payment_method'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? (method['color'] as Color)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['id'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (method['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            method['icon'],
                            color: method['color'],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['name'],
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                method['description'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: method['color'],
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),

            // 支付按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _selectedPaymentMethod == null || _isProcessing
                    ? null
                    : () => _processPayment(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_processingStatus ?? 'processing'.tr()),
                        ],
                      )
                    : Text('pay_now'.tr()),
              ),
            ),
            const SizedBox(height: 16),

            // 安全提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'secure_payment_notice'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;

    // 特殊处理银行转账
    if (_selectedPaymentMethod == 'bank_transfer') {
      await _handleBankTransfer();
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'connecting'.tr();
    });

    // 模拟连接支付网关
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _processingStatus = 'processing_payment'.tr();
    });

    // 模拟支付处理
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 创建支付记录
    final now = DateTime.now();
    final transactionId = 'TXN${now.millisecondsSinceEpoch}';

    if (widget.bills != null) {
      // 批量支付
      for (final bill in widget.bills!) {
        final payment = PaymentModel(
          id: 'pay_${now.millisecondsSinceEpoch}_${bill.id}',
          userId: MockData.currentUser!.id,
          billId: bill.id,
          amount: bill.amount,
          paymentDate: now,
          paymentMethod: _selectedPaymentMethod!,
          transactionId: transactionId,
          status: 'success',
        );

        // 添加到支付记录
        MockData.payments.add(payment);

        // 更新账单状态（本地）
        final billIndex = MockData.bills.indexWhere((b) => b.id == bill.id);
        if (billIndex != -1) {
          MockData.bills[billIndex] = bill.copyWith(
            status: 'paid',
            paymentId: payment.id,
          );
        }

        // Persist payment and bill status to Firestore
        try {
          final createdPaymentId = await FirestoreService.createPayment(payment.toMap());
          await FirestoreService.updateBillStatus(bill.id, 'paid', paymentId: createdPaymentId);
        } catch (e) {
          // Log error but don't crash the UI flow
          debugPrint('Error saving payment/bill status to Firestore for bill ${bill.id}: $e');
        }
      }
    } else {
      // 单个支付
      final payment = PaymentModel(
        id: 'pay_${now.millisecondsSinceEpoch}',
        userId: MockData.currentUser!.id,
        billId: widget.bill.id,
        amount: widget.bill.amount,
        paymentDate: now,
        paymentMethod: _selectedPaymentMethod!,
        transactionId: transactionId,
        status: 'success',
      );

      // 添加到支付记录（本地）
      MockData.payments.add(payment);

      // 更新账单状态（本地）
      final billIndex = MockData.bills.indexWhere((b) => b.id == widget.bill.id);
      if (billIndex != -1) {
        MockData.bills[billIndex] = widget.bill.copyWith(
          status: 'paid',
          paymentId: payment.id,
        );
      }

      // Persist payment and bill status to Firestore
      try {
        final createdPaymentId = await FirestoreService.createPayment(payment.toMap());
        await FirestoreService.updateBillStatus(widget.bill.id, 'paid', paymentId: createdPaymentId);
      } catch (e) {
        debugPrint('Error saving payment/bill status to Firestore for bill ${widget.bill.id}: $e');
      }
    }

    setState(() {
      _processingStatus = 'payment_successful'.tr();
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 显示成功页面
    _showSuccessDialog();
  }

  Future<void> _handleBankTransfer() async {
    final currentUser = MockData.currentUser;
    if (currentUser == null) return;

    // 检查用户是否有银行信息
    final banksSnapshot = await FirestoreService.getUserBanksStream(currentUser.id).first;
    final hasBanks = banksSnapshot.isNotEmpty;

    if (!hasBanks) {
      // 用户没有银行信息，显示提示并跳转到银行管理页面
      final shouldAddBank = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Payment Method'),
          content: const Text(
            'You haven\'t added any bank accounts for payment. Would you like to add one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add Bank Account'),
            ),
          ],
        ),
      );

      if (shouldAddBank == true) {
        // 跳转到银行管理页面
        await Navigator.pushNamed(context, AppRoutes.manageBanks);
        // 返回后重新检查
        if (mounted) {
          await _handleBankTransfer();
        }
      }
    } else {
      // 用户有银行信息，跳转到银行支付界面
      await Navigator.pushNamed(
        context,
        AppRoutes.bankTransfer,
        arguments: {
          'bill': widget.bill,
          'bills': widget.bills,
        },
      ).then((_) {
        // 支付完成后返回到账单页面
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'payment_successful'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'RM ${_totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'transaction_completed'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context); // 返回上一页
                // 刷新页面
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Text('done'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}










