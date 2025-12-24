import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  /// Combined simple address: "<Building> <Floor><Unit>" e.g. "Alpha Building G01"
  final String propertySimpleAddress;
  final String role; // 'resident' or 'admin'
  final DateTime createdAt;
  final String? avatar; // 头像URL

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.propertySimpleAddress,
    this.role = 'resident',
    required this.createdAt,
    this.avatar,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      propertySimpleAddress: map['propertySimpleAddress'] ?? '',
      role: map['role'] ?? 'resident',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : (map['createdAt'] is DateTime
                  ? map['createdAt'] as DateTime
                  : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()))
          : DateTime.now(),
      avatar: map['avatar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'propertySimpleAddress': propertySimpleAddress,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? name,
    String? phoneNumber,
    String? propertySimpleAddress,
    String? avatar,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      propertySimpleAddress: propertySimpleAddress ?? this.propertySimpleAddress,
      role: role,
      createdAt: createdAt,
      avatar: avatar ?? this.avatar,
    );
  }
}

