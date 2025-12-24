import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../models/payment_model.dart';
import '../models/repair_model.dart';
import '../models/announcement_model.dart';
import '../models/package_model.dart';
import '../models/parking_model.dart';

class MockData {
  // 当前登录用户（初始为空，登录后设置）
  static UserModel? currentUser;

  // 测试账号列表
  static final List<Map<String, String>> testAccounts = [
    {
      'email': 'user@property.com',
      'password': '123456',
      'role': 'resident',
    },
    {
      'email': 'admin@property.com',
      'password': 'admin123',
      'role': 'admin',
    },
  ];

  // 用户数据库
  static final Map<String, UserModel> users = {
    'user@property.com': UserModel(
      id: 'user_001',
      email: 'user@property.com',
      name: 'Zhang San',
      phoneNumber: '012-345-6789',
      propertySimpleAddress: 'Green Valley G01',
      role: 'resident',
      createdAt: DateTime(2024, 1, 15),
      avatar: 'https://ui-avatars.com/api/?name=Zhang+San&size=200&background=4CAF50&color=fff',
    ),
    'admin@property.com': UserModel(
      id: 'admin_001',
      email: 'admin@property.com',
      name: 'Admin Manager',
      phoneNumber: '012-999-8888',
      propertySimpleAddress: 'Green Valley Management Office',
      role: 'admin',
      createdAt: DateTime(2024, 1, 1),
      avatar: 'https://ui-avatars.com/api/?name=Admin+Manager&size=200&background=FF5722&color=fff',
    ),
  };

  // 账单列表
  static List<BillModel> bills = [
    BillModel(
      id: 'bill_001',
      userId: 'user_001',
      payerName: 'Zhang San',
      propertySimpleAddress: 'Green Valley G01',
      title: 'Monthly Maintenance Fee - January 2025',
      description: 'Property maintenance and management services',
      amount: 280.00,
      dueDate: DateTime(2025, 1, 31),
      billingDate: DateTime(2025, 1, 1),
      status: 'unpaid',
      category: 'maintenance',
    ),
    BillModel(
      id: 'bill_002',
      userId: 'user_001',
      payerName: 'Zhang San',
      propertySimpleAddress: 'Green Valley G01',
      title: 'Parking Fee - January 2025',
      description: 'Monthly parking space A-105',
      amount: 80.00,
      dueDate: DateTime(2025, 1, 31),
      billingDate: DateTime(2025, 1, 1),
      status: 'unpaid',
      category: 'parking',
    ),
    BillModel(
      id: 'bill_003',
      userId: 'user_001',
      payerName: 'Zhang San',
      propertySimpleAddress: 'Green Valley G01',
      title: 'Water Bill - December 2024',
      description: 'Water consumption: 15 cubic meters',
      amount: 45.50,
      dueDate: DateTime(2024, 12, 31),
      billingDate: DateTime(2024, 12, 1),
      status: 'paid',
      category: 'water',
      paymentId: 'pay_001',
    ),
    BillModel(
      id: 'bill_004',
      userId: 'user_001',
      payerName: 'Zhang San',
      propertySimpleAddress: 'Green Valley G01',
      title: 'Electricity Bill - December 2024',
      description: 'Electricity consumption: 320 kWh',
      amount: 156.80,
      dueDate: DateTime(2024, 12, 31),
      billingDate: DateTime(2024, 12, 1),
      status: 'paid',
      category: 'electricity',
      paymentId: 'pay_002',
    ),
    BillModel(
      id: 'bill_005',
      userId: 'user_001',
      payerName: 'Zhang San',
      propertySimpleAddress: 'Green Valley G01',
      title: 'Internet Service - December 2024',
      description: '100Mbps fiber broadband',
      amount: 89.00,
      dueDate: DateTime(2024, 12, 31),
      billingDate: DateTime(2024, 12, 1),
      status: 'paid',
      category: 'other',
      paymentId: 'pay_003',
    ),
  ];

  // 支付记录
  static List<PaymentModel> payments = [
    PaymentModel(
      id: 'pay_001',
      userId: 'user_001',
      billId: 'bill_003',
      amount: 45.50,
      paymentDate: DateTime(2024, 12, 15, 14, 30),
      paymentMethod: 'wechat',
      transactionId: 'TXN1702647000123',
      status: 'success',
    ),
    PaymentModel(
      id: 'pay_002',
      userId: 'user_001',
      billId: 'bill_004',
      amount: 156.80,
      paymentDate: DateTime(2024, 12, 18, 10, 15),
      paymentMethod: 'alipay',
      transactionId: 'TXN1702906500456',
      status: 'success',
    ),
    PaymentModel(
      id: 'pay_003',
      userId: 'user_001',
      billId: 'bill_005',
      amount: 89.00,
      paymentDate: DateTime(2024, 12, 20, 16, 45),
      paymentMethod: 'bank_transfer',
      transactionId: 'TXN1703079900789',
      status: 'success',
    ),
  ];

  // 报修记录
  static List<RepairModel> repairs = [
    RepairModel(
      id: 'repair_001',
      userId: 'user_001',
      title: 'Leaking Faucet in Kitchen',
      description: 'The kitchen sink faucet has been leaking for 2 days. Water drips continuously.',
      status: 'in_progress',
      priority: 'high',
      location: 'Kitchen',
      createdAt: DateTime(2025, 1, 15, 9, 30),
    ),
    RepairModel(
      id: 'repair_002',
      userId: 'user_002',
      title: 'Air Conditioner Not Cooling',
      description: 'Master bedroom AC unit is running but not cooling properly.',
      status: 'pending',
      priority: 'medium',
      location: 'Bedroom',
      createdAt: DateTime(2025, 1, 18, 14, 20),
    ),
    RepairModel(
      id: 'repair_003',
      userId: 'user_003',
      title: 'Broken Door Lock',
      description: 'Main door lock is jammed, difficult to open.',
      status: 'completed',
      priority: 'high',
      location: 'Main Door',
      createdAt: DateTime(2024, 12, 10, 11, 0),
      completedAt: DateTime(2024, 12, 12, 15, 30),
    ),
  ];

  // 社区公告 - 已迁移至 Firestore，开发时保留空列表作为占位
  static List<AnnouncementModel> announcements = [];


  // 快递包裹
  static List<PackageModel> packages = [
    PackageModel(
      id: 'pkg_001',
      userId: 'user_001',
      trackingNumber: 'SF1234567890',
      courier: 'SF Express',
      description: 'Taobao Package - Clothing',
      status: 'ready_for_pickup',
      arrivedAt: DateTime(2025, 1, 18, 9, 30),
      location: 'Management Office - Shelf A3',
      image: 'https://picsum.photos/400/300?random=30',
    ),
    PackageModel(
      id: 'pkg_002',
      userId: 'user_001',
      trackingNumber: 'JT9876543210',
      courier: 'J&T Express',
      description: 'Shopee Package - Electronics',
      status: 'ready_for_pickup',
      arrivedAt: DateTime(2025, 1, 17, 15, 20),
      location: 'Management Office - Shelf B1',
      image: 'https://picsum.photos/400/300?random=31',
    ),
    PackageModel(
      id: 'pkg_003',
      userId: 'user_001',
      trackingNumber: 'POS2468101214',
      courier: 'Pos Laju',
      description: 'Document',
      status: 'collected',
      arrivedAt: DateTime(2025, 1, 15, 11, 0),
      collectedAt: DateTime(2025, 1, 16, 18, 30),
      location: 'Management Office',
    ),
  ];


  // 停车位信息
  static List<ParkingModel> parkingSpaces = [
    ParkingModel(
      id: 'parking_001',
      userId: 'user_001',
      vehicle: 'ABC 1234',
      model: 'Toyota Camry',
      fee: 80.00,
      startDate: DateTime(2024, 1, 1),
      duration: 12,
      status: 'active',
    ),
  ];

  // 获取统计数据
  static Map<String, dynamic> getStatistics() {
    final unpaidBills = bills.where((b) => b.status == 'unpaid').toList();
    final unpaidTotal = unpaidBills.fold<double>(0, (sum, b) => sum + b.amount);
    final paidTotal = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final pendingRepairs = repairs.where((r) => r.status != 'completed').length;
    final readyPackages = packages.where((p) => p.status == 'ready_for_pickup').length;

    return {
      'unpaidBills': unpaidBills.length,
      'unpaidTotal': unpaidTotal,
      'paidTotal': paidTotal,
      'pendingRepairs': pendingRepairs,
      'readyPackages': readyPackages,
      'totalAnnouncements': announcements.length,
      'activeParking': parkingSpaces.where((p) => p.status == 'active').length,
    };
  }
}

