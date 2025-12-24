import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String userId;
  final String payerName;
  final String propertySimpleAddress;
  final String title;
  final String description;
  final double amount;
  final double penalty; // 新增：滞纳金/罚金
  final DateTime dueDate;
  final DateTime billingDate;
  final String status; // 'unpaid', 'paid', 'overdue'
  final String category; // 'maintenance', 'parking', 'water', 'electricity', 'gas', 'other'
  final String? paymentId;
  final DateTime? lastNotificationDate; // 新增：用于每日通知控制

  BillModel({
    required this.id,
    required this.userId,
    required this.payerName,
    required this.propertySimpleAddress,
    required this.title,
    required this.description,
    required this.amount,
    this.penalty = 0.0, // 默认为0
    required this.dueDate,
    required this.billingDate,
    this.status = 'unpaid',
    required this.category,
    this.paymentId,
    this.lastNotificationDate,
  });

  // 获取总金额（本金 + 罚金）
  double get totalAmount => amount + penalty;

  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    return BillModel(
      id: id,
      userId: map['userId'] ?? '',
      payerName: map['payerName'] ?? '',
      propertySimpleAddress: map['propertySimpleAddress'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      penalty: (map['penalty'] ?? 0).toDouble(), // 读取罚金
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      billingDate: map['billingDate'] is Timestamp
          ? (map['billingDate'] as Timestamp).toDate()
          : DateTime.parse(map['billingDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'unpaid',
      category: map['category'] ?? 'other',
      paymentId: map['paymentId'],
      lastNotificationDate: map['lastNotificationDate'] != null
          ? (map['lastNotificationDate'] is Timestamp
          ? (map['lastNotificationDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastNotificationDate'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'payerName': payerName,
      'propertySimpleAddress': propertySimpleAddress,
      'title': title,
      'description': description,
      'amount': amount,
      'penalty': penalty, // 保存罚金
      'dueDate': Timestamp.fromDate(dueDate), // 建议统一存为 Timestamp
      'billingDate': Timestamp.fromDate(billingDate),
      'status': status,
      'category': category,
      'paymentId': paymentId,
      'lastNotificationDate': lastNotificationDate != null
          ? Timestamp.fromDate(lastNotificationDate!)
          : null,
    };
  }

  // 修改判断逻辑：如果状态是 overdue 或者 (unpaid 且时间过了) 都算 overdue
  bool get isOverdue =>
      status == 'overdue' || (status == 'unpaid' && DateTime.now().isAfter(dueDate));

  String get statusText {
    if (isOverdue) return 'Overdue';
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Unpaid';
      default:
        return status;
    }
  }

  BillModel copyWith({
    String? status,
    String? paymentId,
    String? payerName,
    String? propertySimpleAddress,
    double? penalty,
    DateTime? lastNotificationDate,
  }) {
    return BillModel(
      id: id,
      userId: userId,
      payerName: payerName ?? this.payerName,
      propertySimpleAddress: propertySimpleAddress ?? this.propertySimpleAddress,
      title: title,
      description: description,
      amount: amount,
      penalty: penalty ?? this.penalty,
      dueDate: dueDate,
      billingDate: billingDate,
      status: status ?? this.status,
      category: category,
      paymentId: paymentId ?? this.paymentId,
      lastNotificationDate: lastNotificationDate ?? this.lastNotificationDate,
    );
  }
}