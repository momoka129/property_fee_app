import 'package:cloud_firestore/cloud_firestore.dart';

class RepairModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final String priority;

  // 状态增加: 'canceled', 'rejected'
  final String status; // 'pending', 'in_progress', 'completed', 'canceled', 'rejected'

  final DateTime createdAt;
  final DateTime? completedAt;

  // 新增字段
  final String? rejectionReason; // 拒绝理由
  final String? workerName;      // 分配的工人名字
  final DateTime? scheduledDate; // 预约维修时间

  RepairModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    this.priority = 'medium',
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
    this.rejectionReason,
    this.workerName,
    this.scheduledDate,
  });

  factory RepairModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RepairModel(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: map['completedAt'] is DateTime
          ? map['completedAt']
          : (map['completedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'],
      workerName: map['workerName'],
      scheduledDate: map['scheduledDate'] is DateTime
          ? map['scheduledDate']
          : (map['scheduledDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rejectionReason': rejectionReason,
      'workerName': workerName,
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'canceled': return 'Canceled';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  // 省略 locationDisplay 和 priorityDisplay，保持原样即可
  String get locationDisplay => location;
  String get priorityDisplay {
    switch (priority) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      default: return priority;
    }
  }
}