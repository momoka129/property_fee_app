import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String userId;
  final String payerName; // 付款人姓名
  /// Combined simple address stored on bills as well
  final String propertySimpleAddress;
  final String title; // 账单名称：物业费、停车费、水费等
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime billingDate;
  final String status; // 'unpaid', 'paid', 'overdue'
  final String category; // 'maintenance', 'parking', 'water', 'electricity', 'gas', 'other'
  final String? paymentId; // 关联的支付记录ID

  BillModel({
    required this.id,
    required this.userId,
    required this.payerName,
    required this.propertySimpleAddress,
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.billingDate,
    this.status = 'unpaid',
    required this.category,
    this.paymentId,
  });

  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    return BillModel(
      id: id,
      userId: map['userId'] ?? '',
      payerName: map['payerName'] ?? '',
      propertySimpleAddress: map['propertySimpleAddress'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.parse(map['dueDate'] ?? DateTime.now().toIso8601String()),
      billingDate: map['billingDate'] is Timestamp
          ? (map['billingDate'] as Timestamp).toDate()
          : DateTime.parse(map['billingDate'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'unpaid',
      category: map['category'] ?? 'other',
      paymentId: map['paymentId'],
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
      'dueDate': dueDate.toIso8601String(),
      'billingDate': billingDate.toIso8601String(),
      'status': status,
      'category': category,
      'paymentId': paymentId,
    };
  }

  bool get isOverdue =>
      status == 'unpaid' && DateTime.now().isAfter(dueDate);

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
  }) {
    return BillModel(
      id: id,
      userId: userId,
      payerName: payerName ?? this.payerName,
      propertySimpleAddress: propertySimpleAddress ?? this.propertySimpleAddress,
      title: title,
      description: description,
      amount: amount,
      dueDate: dueDate,
      billingDate: billingDate,
      status: status ?? this.status,
      category: category,
      paymentId: paymentId ?? this.paymentId,
    );
  }
}