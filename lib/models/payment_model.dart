class PaymentModel {
  final String id;
  final String userId;
  final String billId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // 'wechat', 'alipay', 'bank_transfer'
  final String transactionId; // 模拟交易ID
  final String status; // 'success', 'pending', 'failed'
  final String? bankId; // 用于银行转账，记录使用的银行账户ID
  final String? notes;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.billId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.transactionId,
    this.status = 'success',
    this.bankId,
    this.notes,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      billId: map['billId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? '',
      transactionId: map['transactionId'] ?? '',
      status: map['status'] ?? 'success',
      bankId: map['bankId'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'billId': billId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'status': status,
      'bankId': bankId,
      'notes': notes,
    };
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'wechat':
        return 'WeChat Pay';
      case 'alipay':
        return 'Alipay';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return paymentMethod;
    }
  }
}

