import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_model.dart';
import '../models/payment_method_model.dart';
import '../widgets/classical_dialog.dart';
import '../widgets/glass_container.dart'; // 务必确保此文件已创建
import '../routes.dart'; // 引入路由

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
  // 选中的支付方式 ID
  String? _selectedId;
  // 选中的支付方式名称
  String? _selectedName;

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

  // --- 支付逻辑 ---

  Future<void> _handleConfirmPayment() async {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a payment method first"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 模拟网络延迟 (2秒)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    await _onPaymentSuccess();
  }

  Future<void> _onPaymentSuccess() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var bill in _targetBills) {
        final docRef =
        FirebaseFirestore.instance.collection('bills').doc(bill.id);
        batch.update(docRef, {
          'status': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
          'paymentMethod': _selectedName ?? 'Unknown Method',
        });
      }
      await batch.commit();

      setState(() => _isLoading = false);
      if (!mounted) return;

      // 弹出支付成功
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ClassicalDialog(
          title: 'Payment Successful',
          content:
          'Paid RM ${_totalAmountToPay.toStringAsFixed(2)} using $_selectedName.\nThank you!',
          confirmText: 'Done',
          onConfirm: () {
            Navigator.of(context).pop(); // 关弹窗
            Navigator.of(context).pop(); // 退出支付页面
          },
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => ClassicalDialog(
        title: 'Error',
        content: msg,
        confirmText: 'Close',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  // --- UI 构建 ---

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true, // 让背景延伸到 AppBar 后面
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // 全局绿色渐变背景，衬托玻璃效果
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20), // 深绿
              Color(0xFF4CAF50), // 中绿
              Color(0xFFA5D6A7), // 浅绿
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. 顶部金额展示区 (玻璃卡片)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  opacity: 0.15,
                  child: Column(
                    children: [
                      const Text(
                        "Total Amount to Pay",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "RM ${_totalAmountToPay.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_targetBills.length} bill(s) selected",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. 支付方式列表
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: "CREDIT / DEBIT CARDS"),
                      const SizedBox(height: 12),

                      // Add Card 按钮
                      _buildAddCardButton(context),

                      const SizedBox(height: 16),

                      // Firestore 监听用户卡片
                      if (user != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('payment_methods')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text("Error loading cards",
                                  style: TextStyle(color: Colors.white70));
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white));
                            }

                            final docs = snapshot.data!.docs;
                            return Column(
                              children: docs.map((doc) {
                                final data =
                                doc.data() as Map<String, dynamic>;
                                final card = PaymentMethodModel.fromMap(
                                    data, doc.id);
                                return _buildPaymentOptionCard(
                                  id: card.id,
                                  name: "${card.type} •••• ${card.last4}",
                                  icon: Icons.credit_card,
                                  iconColor: card.type == 'Visa'
                                      ? Colors.blueAccent
                                      : Colors.orangeAccent,
                                  subtitle: card.holderName,
                                );
                              }).toList(),
                            );
                          },
                        ),

                      const SizedBox(height: 24),
                      const SectionTitle(title: "E-WALLETS & OTHERS"),
                      const SizedBox(height: 12),

                      // 预置的常用支付方式
                      _buildPaymentOptionCard(
                        id: 'grab',
                        name: 'GrabPay',
                        icon: Icons.local_taxi,
                        iconColor: Colors.greenAccent,
                        subtitle: 'Linked: 012-*** 8888',
                      ),
                      _buildPaymentOptionCard(
                        id: 'tng',
                        name: 'Touch \'n Go eWallet',
                        icon: Icons.touch_app,
                        iconColor: Colors.blue,
                        subtitle: 'Balance: RM 500.00',
                      ),
                      _buildPaymentOptionCard(
                        id: 'paypal',
                        name: 'PayPal',
                        icon: Icons.payment,
                        iconColor: Colors.indigoAccent,
                        subtitle: 'user@example.com',
                      ),

                      const SizedBox(height: 100), // 底部留白给按钮
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 底部确认按钮区
      bottomSheet: Container(
        color: Colors.transparent, // 或者是背景色
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          opacity: 0.9, // 底部背景稍微实一点，看得清按钮
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  _selectedId == null
                      ? "Select Payment Method"
                      : "Confirm Payment",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 组件构建 ---

  // 1. Add Card 按钮 (玻璃风格)
  Widget _buildAddCardButton(BuildContext context) {
    return GlassContainer(
      opacity: 0.15,
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // 关键逻辑：跳转到路由表中定义的管理页面
        Navigator.pushNamed(context, AppRoutes.managePaymentMethods);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_circle_outline, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Add New Card",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 2. 支付选项卡片 (玻璃风格 + 选中状态)
  Widget _buildPaymentOptionCard({
    required String id,
    required String name,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
  }) {
    final isSelected = _selectedId == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        opacity: isSelected ? 0.25 : 0.1,
        borderRadius: BorderRadius.circular(16),
        // 选中时添加绿色边框
        onTap: () {
          setState(() {
            _selectedId = id;
            _selectedName = name;
          });
        },
        child: Row(
          children: [
            // 图标容器
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),

            // 文本信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white, // 深色背景用白字
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 选中对号
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 28)
            else
              Icon(Icons.circle_outlined,
                  color: Colors.white.withOpacity(0.3), size: 28),
          ],
        ),
      ),
    );
  }
}

// 辅助标题组件
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white.withOpacity(0.6),
        letterSpacing: 1.2,
      ),
    );
  }
}