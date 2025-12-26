import 'package:cloud_firestore/cloud_firestore.dart';

class RepairModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final String priority;

  // 状态: 'pending', 'in_progress', 'completed', 'canceled', 'rejected'
  final String status;

  final DateTime createdAt;
  final DateTime? completedAt;

  // --- 1. 列表页需要的图片字段 ---
  final List<String> images;

  // --- 2. 新增字段 (注意：时间字段统一定义为 repairDate) ---
  final String? rejectionReason; // 拒绝理由
  final String? workerName;      // 分配的工人名字
  final String? workerId;        // 工人ID (用于关联)
  final DateTime? repairDate;    // 维修/预约时间 (统一字段名)

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
    this.images = const [], // 默认为空列表
    this.rejectionReason,
    this.workerName,
    this.workerId,
    this.repairDate,
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
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : null,

      // 安全转换图片
      images: List<String>.from(map['images'] ?? []),

      rejectionReason: map['rejectionReason'],
      workerName: map['workerName'],
      workerId: map['workerId'],

      // 统一读取 repairDate
      repairDate: map['repairDate'] is Timestamp
          ? (map['repairDate'] as Timestamp).toDate()
          : null,
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
      'images': images,
      'rejectionReason': rejectionReason,
      'workerName': workerName,
      'workerId': workerId,
      // 统一写入 repairDate
      'repairDate': repairDate != null ? Timestamp.fromDate(repairDate!) : null,
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