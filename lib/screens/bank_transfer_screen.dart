import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bill_model.dart';
import '../models/bank_model.dart';
import '../models/payment_model.dart';
import '../data/mock_data.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../routes.dart';

class BankTransferScreen extends StatefulWidget {
  final BillModel bill;
  final List<BillModel>? bills; // 用于批量支付

  const BankTransferScreen({
    super.key,
    required this.bill,
    this.bills,
  });

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  bool _isProcessing = false;
  String? _processingStatus;
  BankModel? _selectedBank;

  double get _totalAmount {
    if (widget.bills != null) {
      return widget.bills!.fold<double>(0, (sum, b) => sum + b.amount);
    }
    return widget.bill.amount;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final user = appProvider.currentUser ?? MockData.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    final isMultiple = widget.bills != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transfer Payment'),
      ),
      body: StreamBuilder<List<BankModel>>(
        stream: FirestoreService.getUserBanksStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final banks = snapshot.data ?? [];

          if (banks.isEmpty) {
            // 用户没有银行信息，显示提示并提供跳转到银行管理页面的按钮
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Payment Method Available',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You need to add a bank account before you can make bank transfer payments.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.manageBanks).then((_) {
                            // 返回时刷新当前页面
                            if (mounted) {
                              setState(() {});
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bank Account'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
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
                          isMultiple ? 'Bills Summary' : 'Bill Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isMultiple) ...[
                          Text(
                            'Total Bills: ${widget.bills!.length}',
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
                              'Total Amount',
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

                // 选择银行账户
                Text(
                  'Select Bank Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...banks.map((bank) {
                  final isSelected = _selectedBank?.id == bank.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedBank = bank;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank.bankName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Account Name: ${bank.accountName}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Account Number: ${bank.accountNumber}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your Account: ${bank.userAccountNumber}',
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
                                color: Theme.of(context).colorScheme.primary,
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
                    onPressed: _selectedBank == null || _isProcessing
                        ? null
                        : () => _processBankTransfer(),
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
                              Text(_processingStatus ?? 'Processing...'),
                            ],
                          )
                        : const Text('Confirm Payment'),
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
                          'Please ensure you have sufficient funds in your account. This transaction will be processed immediately.',
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
          );
        },
      ),
    );
  }

  Future<void> _processBankTransfer() async {
    if (_selectedBank == null) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Processing payment...';
    });

    // 模拟支付处理
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 创建支付记录
    final now = DateTime.now();
    final transactionId = 'BT${now.millisecondsSinceEpoch}';

    if (widget.bills != null) {
      // 批量支付
      for (final bill in widget.bills!) {
        final payment = PaymentModel(
          id: 'pay_${now.millisecondsSinceEpoch}_${bill.id}',
          userId: MockData.currentUser!.id,
          billId: bill.id,
          amount: bill.amount,
          paymentDate: now,
          paymentMethod: 'bank_transfer',
          transactionId: transactionId,
          status: 'success',
          bankId: _selectedBank!.id,
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

        // 保存到Firestore
        try {
          final createdPaymentId = await FirestoreService.createPayment(payment.toMap());
          await FirestoreService.updateBillStatus(bill.id, 'paid', paymentId: createdPaymentId);
        } catch (e) {
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
        paymentMethod: 'bank_transfer',
        transactionId: transactionId,
        status: 'success',
        bankId: _selectedBank!.id,
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

      // 保存到Firestore
      try {
        final createdPaymentId = await FirestoreService.createPayment(payment.toMap());
        await FirestoreService.updateBillStatus(widget.bill.id, 'paid', paymentId: createdPaymentId);
      } catch (e) {
        debugPrint('Error saving payment/bill status to Firestore for bill ${widget.bill.id}: $e');
      }
    }

    setState(() {
      _processingStatus = 'Payment successful!';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 显示成功页面
    _showSuccessDialog();
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
              'Payment Successful!',
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
              'Bank transfer completed successfully.',
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
                Navigator.pop(context); // 返回支付页面
                Navigator.pop(context); // 返回账单详情页面
                // 刷新页面
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}


