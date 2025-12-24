import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotificationModel {
  final String id;
  final String billId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  UserNotificationModel({
    required this.id,
    required this.billId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  factory UserNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    DateTime created = DateTime.now();
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    }

    return UserNotificationModel(
      id: id,
      billId: map['billId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: created,
      read: (map['read'] ?? false) as bool,
    );
  }
}




