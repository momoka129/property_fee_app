class PaymentMethodModel {
  final String id;
  final String type; // 'Visa', 'MasterCard', 'TNG', etc.
  final String last4; // 卡号后四位
  final String holderName;
  final bool isDefault;

  PaymentMethodModel({
    required this.id,
    required this.type,
    required this.last4,
    required this.holderName,
    this.isDefault = false,
  });

  // 模拟从 Firestore 读取
  factory PaymentMethodModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentMethodModel(
      id: id,
      type: map['type'] ?? 'Visa',
      last4: map['last4'] ?? '0000',
      holderName: map['holderName'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'last4': last4,
      'holderName': holderName,
      'isDefault': isDefault,
    };
  }
}