import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 引入这个以使用输入格式化
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method_model.dart';
import '../widgets/glass_container.dart';

class ManagePaymentMethodsScreen extends StatefulWidget {
  const ManagePaymentMethodsScreen({super.key});

  @override
  State<ManagePaymentMethodsScreen> createState() =>
      _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState
    extends State<ManagePaymentMethodsScreen> {
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  // --- 1. 显示添加卡片弹窗 (含验证逻辑) ---
  void _showAddCardDialog() {
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    // 创建一个 FormKey 来管理表单状态
    final formKey = GlobalKey<FormState>();
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // 保持背景通透
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          opacity: 0.95,
          blur: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            // 使用 Form 包裹输入框
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Add New Card",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 卡号输入框 ---
                  TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    maxLength: 16, // 限制最大长度
                    // 限制只能输入数字
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Card Number', // 移除 Mock 字样
                      counterText: "", // 隐藏右下角的计数器
                      prefixIcon: const Icon(Icons.credit_card),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      errorBorder: OutlineInputBorder( // 错误时的边框颜色
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    // 校验逻辑
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Card number is required';
                      }
                      if (value.length < 13) {
                        return 'Card number is too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- 持卡人姓名输入框 ---
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Cardholder Name',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    // 校验逻辑
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Cardholder name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- 按钮区域 ---
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.grey[600],
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // 点击按钮时触发校验
                            if (formKey.currentState!.validate()) {
                              // 只有校验通过才执行添加
                              _addCardToFirestore(
                                number: numberController.text,
                                holderName: nameController.text,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Add Card"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. 核心逻辑：添加卡片到数据库 ---
  Future<void> _addCardToFirestore(
      {required String number, required String holderName}) async {
    if (_userId == null) return;

    // 智能推断卡类型
    String type = 'Unknown';
    if (number.startsWith('4')) {
      type = 'Visa';
    } else if (number.startsWith('5')) {
      type = 'MasterCard';
    } else if (number.startsWith('3')) {
      type = 'Amex';
    } else {
      // 随机兜底，为了演示好看
      type = Random().nextBool() ? 'Visa' : 'MasterCard';
    }

    // 获取后四位
    String last4 = number.length > 4
        ? number.substring(number.length - 4)
        : number;

    final newCard = PaymentMethodModel(
      id: '',
      type: type,
      last4: last4,
      holderName: holderName.toUpperCase(), // 自动转大写
      isDefault: false,
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('payment_methods')
        .get();

    final isFirst = snapshot.docs.isEmpty;
    final cardData = newCard.toMap();
    if (isFirst) cardData['isDefault'] = true;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('payment_methods')
        .add(cardData);
  }

  // --- 3. 删除卡片逻辑 ---
  Future<void> _deleteCard(String cardId) async {
    if (_userId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('payment_methods')
        .doc(cardId)
        .delete();
  }

  // --- 4. 设置默认卡片逻辑 ---
  Future<void> _setDefault(String cardId) async {
    if (_userId == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('payment_methods');

    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == cardId});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // 1. 定义背景渐变 (与 Profile/Admin 页面保持一致)
    final Color bgGradientStart = const Color(0xFFF3F4F6);
    final Color bgGradientEnd = const Color(0xFFE5E7EB);

    return Scaffold(
      extendBodyBehindAppBar: true, // 让背景延伸到 AppBar 后面
      appBar: AppBar(
        title: const Text(
          "Payment Methods",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        // 2. 使用渐变背景，衬托白色玻璃
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .collection('payment_methods')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(color: primaryColor));
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: [
                  Expanded(
                    child: docs.isEmpty
                        ? const Center(
                        child: Text("No cards yet.",
                            style: TextStyle(color: Colors.black54)))
                        : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                        docs[index].data() as Map<String, dynamic>;
                        final card = PaymentMethodModel.fromMap(
                            data, docs[index].id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          // 3. 列表项使用 GlassContainer
                          child: GlassContainer(
                            // 【修正】移除 color 参数
                            opacity: 0.8,
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _setDefault(card.id),
                            child: Row(
                              children: [
                                // 卡片图标容器
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    // 如果是默认卡，图标背景稍微带点主色
                                      color: card.isDefault
                                          ? primaryColor.withOpacity(0.1)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: card.isDefault
                                              ? primaryColor.withOpacity(0.3)
                                              : Colors.transparent
                                      )
                                  ),
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    color: card.type == 'Visa'
                                        ? Colors.blue
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${card.type} •••• ${card.last4}",
                                        style: TextStyle(
                                          color: card.isDefault
                                              ? primaryColor
                                              : Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        card.isDefault
                                            ? "Default"
                                            : "Tap to set default",
                                        style: TextStyle(
                                            color: card.isDefault
                                                ? primaryColor.withOpacity(0.8)
                                                : Colors.black54,
                                            fontSize: 12,
                                            fontWeight: card.isDefault ? FontWeight.w600 : FontWeight.normal
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 如果是默认卡，显示一个勾选图标
                                if (card.isDefault)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.black38),
                                  onPressed: () => _deleteCard(card.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 4. 底部添加按钮
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GlassContainer(
                      // 【修正】移除 color: primaryColor
                      opacity: 0.9,
                      borderRadius: BorderRadius.circular(20),
                      onTap: _showAddCardDialog,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "Add New Card",
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}