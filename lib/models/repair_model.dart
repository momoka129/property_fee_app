import 'package:cloud_firestore/cloud_firestore.dart';

class RepairModel {
  final String id;
  final String userId; // ID of the user who submitted the repair request
  final String title;
  final String description;
  final String location; // 'Kitchen', 'Bedroom', 'Bathroom', 'Main Door', 'Living Room'
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime createdAt;
  final DateTime? completedAt;

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
  });

  // Factory constructor to create RepairModel from Firestore document
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
    );
  }

  // Convert RepairModel to Map for Firestore
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
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String get locationDisplay {
    return location;
  }

  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        return priority;
    }
  }
}








