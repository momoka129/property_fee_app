import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead; // 必须是 bool
  final DateTime createdAt;
  final String type;
  final String? relatedId;

  UserNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.type,
    this.relatedId,
  });

  factory UserNotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return UserNotificationModel(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      // ⚠️ 重点：确保这里能正确处理 null，且强制转为 bool
      isRead: data['isRead'] == true,
      // 处理 Timestamp
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'general',
      relatedId: data['relatedId'],
    );
  }
}