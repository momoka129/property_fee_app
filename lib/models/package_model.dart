import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String userId;
  final String trackingNumber;
  final String courier;
  final String description;
  final String status; // 'ready_for_pickup', 'collected', 'returned'
  final DateTime arrivedAt;
  final DateTime? collectedAt;
  final String location;
  final String? image;
  final String? notes;

  PackageModel({
    required this.id,
    required this.userId,
    required this.trackingNumber,
    required this.courier,
    required this.description,
    this.status = 'ready_for_pickup',
    required this.arrivedAt,
    this.collectedAt,
    required this.location,
    this.image,
    this.notes,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map, String id) {
    return PackageModel(
      id: id,
      userId: map['userId'] ?? '',
      trackingNumber: map['trackingNumber'] ?? '',
      courier: map['courier'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'ready_for_pickup',
      arrivedAt: map['arrivedAt'] is Timestamp
          ? (map['arrivedAt'] as Timestamp).toDate()
          : DateTime.parse(map['arrivedAt'] ?? DateTime.now().toIso8601String()),
      collectedAt: map['collectedAt'] != null
          ? (map['collectedAt'] is Timestamp
              ? (map['collectedAt'] as Timestamp).toDate()
              : DateTime.parse(map['collectedAt']))
          : null,
      location: map['location'] ?? '',
      image: map['image'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'trackingNumber': trackingNumber,
      'courier': courier,
      'description': description,
      'status': status,
      'arrivedAt': arrivedAt.toIso8601String(),
      'collectedAt': collectedAt?.toIso8601String(),
      'location': location,
      'image': image,
      'notes': notes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'collected':
        return 'Collected';
      case 'returned':
        return 'Returned to Sender';
      default:
        return status;
    }
  }

  int get waitingDays {
    if (collectedAt != null) {
      return collectedAt!.difference(arrivedAt).inDays;
    }
    return DateTime.now().difference(arrivedAt).inDays;
  }
}












