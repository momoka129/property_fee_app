import 'package:cloud_firestore/cloud_firestore.dart';

class BankModel {
  final String id;
  final String userId;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String userAccountNumber;
  final DateTime createdAt;

  BankModel({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.userAccountNumber,
    required this.createdAt,
  });

  factory BankModel.fromMap(Map<String, dynamic> map, String id) {
    return BankModel(
      id: id,
      userId: map['userId'] ?? '',
      bankName: map['bankName'] ?? '',
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      userAccountNumber: map['userAccountNumber'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : (map['createdAt'] is DateTime
                  ? map['createdAt'] as DateTime
                  : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'userAccountNumber': userAccountNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


