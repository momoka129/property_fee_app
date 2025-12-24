import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingModel {
  final String id;
  final String userId;
  final String vehicle; // 车牌
  final String model; // 车的特定品牌
  final double fee; // 每个月的费用
  final DateTime startDate; // 开始日期
  final int duration; // 有效持续时间（以月为单位）
  final String status; // 'active' or 'expiring_soon'

  ParkingModel({
    required this.id,
    required this.userId,
    required this.vehicle,
    required this.model,
    required this.fee,
    required this.startDate,
    required this.duration,
    this.status = 'active',
  });

  factory ParkingModel.fromMap(Map<String, dynamic> map, String id) {
    return ParkingModel(
      id: id,
      userId: map['userId'] ?? '',
      vehicle: map['vehicle'] ?? '',
      model: map['model'] ?? '',
      fee: (map['fee'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] is DateTime
          ? map['startDate']
          : (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vehicle': vehicle,
      'model': model,
      'fee': fee,
      'startDate': Timestamp.fromDate(startDate),
      'duration': duration,
      'status': status,
    };
  }

  /// Effective status calculated from expiry date.
  /// If expiry is at least ~2 months away, it's 'active', otherwise 'expiring_soon'.
  String get effectiveStatus {
    final now = DateTime.now();
    final daysUntilExpiry = endDate.difference(now).inDays;
    // ~2 months threshold (60 days)
    if (daysUntilExpiry >= 60) return 'active';
    if (daysUntilExpiry >= 0) return 'expiring_soon';
    // already expired - treat as expiring_soon for display purposes
    return 'expiring_soon';
  }

  String get statusDisplay {
    switch (effectiveStatus) {
      case 'active':
        return 'Active';
      case 'expiring_soon':
        return 'Expiring Soon';
      default:
        return effectiveStatus;
    }
  }

  // 计算到期日期
  DateTime get endDate {
    return DateTime(startDate.year, startDate.month + duration, startDate.day);
  }

  // Check if expiring soon (within ~2 months before expiry)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final expiryDate = endDate;
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry < 60 && daysUntilExpiry >= 0;
  }
}












