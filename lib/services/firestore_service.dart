import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../models/package_model.dart';
import '../models/repair_model.dart';
import '../models/bank_model.dart';
import '../models/user_notification_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns a stream of announcements ordered by publishedAt (desc).
  static Stream<List<AnnouncementModel>> announcementsStream({int? limit}) {
    Query query = _db.collection('announcements').orderBy(
        'publishedAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AnnouncementModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Admin: create a new announcement document.
  /// The `data` map should contain keys matching Firestore rules:
  /// title, summary, content, communityId, category, priority, status,
  /// publishedAt (DateTime or Timestamp), expireAt (optional DateTime or Timestamp or null),
  /// createdBy (string), pinned (bool), image (string|null)
  static Future<String> createAnnouncement(Map<String, dynamic> data) async {
    final docRef = _db.collection('announcements').doc();

    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp when needed
    if (payload['publishedAt'] is DateTime) {
      payload['publishedAt'] =
          Timestamp.fromDate(payload['publishedAt'] as DateTime);
    }
    if (payload.containsKey('expireAt') && payload['expireAt'] is DateTime) {
      payload['expireAt'] = Timestamp.fromDate(payload['expireAt'] as DateTime);
    }

    // Expect 'author' and 'isPinned' keys directly from client; do not write legacy 'createdBy'/'pinned' or 'communityId'.

    await docRef.set(payload);
    return docRef.id;
  }

  /// Admin: update an existing announcement
  static Future<void> updateAnnouncement(String id,
      Map<String, dynamic> data) async {
    final docRef = _db.collection('announcements').doc(id);
    final Map<String, dynamic> payload = Map.from(data);
    if (payload['publishedAt'] is DateTime) {
      payload['publishedAt'] =
          Timestamp.fromDate(payload['publishedAt'] as DateTime);
    }
    if (payload.containsKey('expireAt') && payload['expireAt'] is DateTime) {
      payload['expireAt'] = Timestamp.fromDate(payload['expireAt'] as DateTime);
    }
    // Do not map legacy 'createdBy'/'pinned' fields here.
    await docRef.update(payload);
  }

  /// Admin: delete announcement
  static Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  // Bills Collection Operations

  /// Get bills stream for a specific user
  static Stream<List<BillModel>> getUserBillsStream(String userId) {
    return _db
        .collection('bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BillModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get bills stream by property unit (fallback when userId does not match)
  static Stream<List<BillModel>> getUserBillsByPropertyAddressStream(
      String propertySimpleAddress) {
    return _db
        .collection('bills')
        .where('propertySimpleAddress', isEqualTo: propertySimpleAddress)
        .orderBy('billingDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BillModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get all bills stream (for admin)
  static Stream<List<BillModel>> getAllBillsStream() {
    return _db
        .collection('bills')
        .orderBy('billingDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BillModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Create a new bill document
  static Future<String> createBill(Map<String, dynamic> data) async {
    final docRef = _db.collection('bills').doc();

    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp
    if (payload['dueDate'] is DateTime) {
      payload['dueDate'] = Timestamp.fromDate(payload['dueDate'] as DateTime);
    }
    if (payload['billingDate'] is DateTime) {
      payload['billingDate'] =
          Timestamp.fromDate(payload['billingDate'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update bill status
  static Future<void> updateBillStatus(String billId, String status,
      {String? paymentId}) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (paymentId != null) {
      updateData['paymentId'] = paymentId;
    }
    await _db.collection('bills').doc(billId).update(updateData);
  }

  /// Update entire bill document (admin)
  static Future<void> updateBill(String billId,
      Map<String, dynamic> data) async {
    final docRef = _db.collection('bills').doc(billId);
    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp
    if (payload['dueDate'] is DateTime) {
      payload['dueDate'] = Timestamp.fromDate(payload['dueDate'] as DateTime);
    }
    if (payload['billingDate'] is DateTime) {
      payload['billingDate'] =
          Timestamp.fromDate(payload['billingDate'] as DateTime);
    }

    await docRef.update(payload);
  }

  /// Delete bill
  static Future<void> deleteBill(String billId) async {
    await _db.collection('bills').doc(billId).delete();
  }

  /// Get bill by ID
  static Future<BillModel?> getBillById(String billId) async {
    final doc = await _db.collection('bills').doc(billId).get();
    if (doc.exists) {
      return BillModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get all users with role 'user' (residents)
  static Future<List<UserModel>> getUsers() async {
    final querySnapshot = await _db.collection('accounts').where(
        'role', isEqualTo: 'user').get();
    return querySnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id);
    }).toList();
  }

  /// Get all users in accounts collection (including admin and user roles)
  static Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _db.collection('accounts').get();
    return querySnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id);
    }).toList();
  }

  /// Migrate all bills and user IDs to a selected user
  /// This will update all bills' userId and payerName to the selected user,
  /// This will update all bills' `userId` and `payerName` to the selected user.
  /// It does NOT modify the `accounts` collection documents themselves.
  static Future<void> migrateAllDataToUser(String selectedUserId) async {
    final batch = _db.batch();

    try {
      // Get the selected user data
      final selectedUserDoc = await _db.collection('accounts').doc(
          selectedUserId).get();
      if (!selectedUserDoc.exists) {
        throw Exception('Selected user does not exist');
      }
      final selectedUser = UserModel.fromMap(
          selectedUserDoc.data()!, selectedUserDoc.id);

      // Update all bills to use the selected user's ID and name
      final billsSnapshot = await _db.collection('bills').get();
      for (final billDoc in billsSnapshot.docs) {
        batch.update(billDoc.reference, {
          'userId': selectedUser.id,
          'payerName': selectedUser.name,
        });
      }

      // Commit the batch
      if (billsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      print('Successfully migrated all bills to user: ${selectedUser
          .name} (${selectedUser.id})');
    } catch (e) {
      print('Error migrating data: $e');
      rethrow;
    }
  }

  // Packages Collection Operations

  /// Get packages stream for a specific user
  static Stream<List<PackageModel>> getUserPackagesStream(String userId) {
    return _db
        .collection('packages')
        .where('userId', isEqualTo: userId)
        .orderBy('arrivedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PackageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get all packages stream (for admin)
  static Stream<List<PackageModel>> getAllPackagesStream() {
    return _db
        .collection('packages')
        .orderBy('arrivedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PackageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Update package status
  static Future<void> updatePackageStatus(String packageId, String status,
      {DateTime? collectedAt}) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (collectedAt != null) {
      updateData['collectedAt'] = Timestamp.fromDate(collectedAt);
    }
    await _db.collection('packages').doc(packageId).update(updateData);
  }

  /// Update entire package document
  static Future<void> updatePackage(String packageId,
      Map<String, dynamic> data) async {
    final docRef = _db.collection('packages').doc(packageId);
    final Map<String, dynamic> payload = Map.from(data);
    // Force location to be the fixed value
    payload['location'] = 'Management Office';

    // Convert DateTime -> Timestamp
    if (payload['arrivedAt'] is DateTime) {
      payload['arrivedAt'] =
          Timestamp.fromDate(payload['arrivedAt'] as DateTime);
    }
    if (payload.containsKey('collectedAt') &&
        payload['collectedAt'] is DateTime) {
      payload['collectedAt'] =
          Timestamp.fromDate(payload['collectedAt'] as DateTime);
    }

    await docRef.update(payload);
  }

  /// Delete package
  static Future<void> deletePackage(String packageId) async {
    await _db.collection('packages').doc(packageId).delete();
  }

  /// Get repairs for a specific user
  static Stream<List<RepairModel>> getUserRepairsStream(String userId) {
    return _db
        .collection('repairs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RepairModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get all repairs (admin)
  static Stream<List<RepairModel>> getAllRepairsStream() {
    return _db
        .collection('repairs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RepairModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Create a new repair request
  static Future<String> createRepair(Map<String, dynamic> data) async {
    final docRef = _db.collection('repairs').doc();

    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp when needed
    if (payload['createdAt'] is DateTime) {
      payload['createdAt'] =
          Timestamp.fromDate(payload['createdAt'] as DateTime);
    }
    if (payload.containsKey('completedAt') &&
        payload['completedAt'] is DateTime) {
      payload['completedAt'] =
          Timestamp.fromDate(payload['completedAt'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update repair status (admin)
  static Future<void> updateRepairStatus(String repairId, String status,
      {DateTime? completedAt}) async {
    final Map<String, dynamic> data = {'status': status};
    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }
    await _db.collection('repairs').doc(repairId).update(data);
  }

  /// Create a new payment
  static Future<String> createPayment(Map<String, dynamic> data) async {
    final docRef = _db.collection('payments').doc();

    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp when needed
    if (payload['paymentDate'] is DateTime) {
      payload['paymentDate'] =
          Timestamp.fromDate(payload['paymentDate'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Get banks for a specific user
  static Stream<List<BankModel>> getUserBanksStream(String userId) {
    return _db
        .collection('banks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BankModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Create a new bank account
  static Future<String> createBank(Map<String, dynamic> data) async {
    final docRef = _db.collection('banks').doc();

    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp when needed
    if (payload['createdAt'] is DateTime) {
      payload['createdAt'] =
          Timestamp.fromDate(payload['createdAt'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update bank account
  static Future<void> updateBank(String bankId,
      Map<String, dynamic> data) async {
    await _db.collection('banks').doc(bankId).update(data);
  }

  /// Delete bank account
  static Future<void> deleteBank(String bankId) async {
    await _db.collection('banks').doc(bankId).delete();
  }

  /// Update user profile
  static Future<void> updateUser(String userId,
      Map<String, dynamic> data) async {
    await _db.collection('accounts').doc(userId).update(data);
  }

  /// Update user avatar
  static Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    await updateUser(userId, {'avatar': avatarUrl});
  }

  /// Create a new user (admin)
  static Future<String> createUser(Map<String, dynamic> data) async {
    final docRef = _db.collection('accounts').doc();
    final Map<String, dynamic> payload = Map.from(data);
    await docRef.set(payload);
    return docRef.id;
  }

  /// Delete user (admin)
  static Future<void> deleteUser(String userId) async {
    await _db.collection('accounts').doc(userId).delete();
  }

  /// Get admin by UID
  static Future<UserModel?> getAdminByUid(String uid) async {
    final querySnapshot = await _db.collection('accounts').where(
        'uid', isEqualTo: uid).where('role', isEqualTo: 'admin').get();
    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(
          querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
    }
    return null;
  }

  /// Get all admins
  static Future<List<UserModel>> getAdmins() async {
    final querySnapshot = await _db.collection('accounts').where(
        'role', isEqualTo: 'admin').get();
    return querySnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id);
    }).toList();
  }

  /// Check if an address already exists in the accounts collection
  static Future<bool> checkAddressExists(String propertySimpleAddress,
      {String? excludeUserId}) async {
    Query query = _db.collection('accounts').where(
        'propertySimpleAddress', isEqualTo: propertySimpleAddress);

    final querySnapshot = await query.get();

    // If excluding a user ID (for updates), filter out that user
    if (excludeUserId != null) {
      final filteredDocs = querySnapshot.docs.where((doc) =>
      doc.id != excludeUserId);
      return filteredDocs.isNotEmpty;
    }

    return querySnapshot.docs.isNotEmpty;
  }

  /// Check if an email already exists in the accounts collection
  static Future<bool> checkEmailExists(String email,
      {String? excludeUserId}) async {
    Query query = _db.collection('accounts').where(
        'email', isEqualTo: email);

    final querySnapshot = await query.get();

    // If excluding a user ID (for updates), filter out that user
    if (excludeUserId != null) {
      final filteredDocs = querySnapshot.docs.where((doc) =>
      doc.id != excludeUserId);
      return filteredDocs.isNotEmpty;
    }

    return querySnapshot.docs.isNotEmpty;
  }


  // 在 FirestoreService 类内部添加以下方法
// 确保导入了 BillModel

  /// 核心逻辑：检查逾期账单、计算罚金并发送通知
  /// 规则：
  /// 1. 如果当前时间 > dueDate，将状态设为 overdue
  /// 2. 每逾期1周（7天），罚金增加本金的 5%
  /// 3. 每天发送一次通知（检查 lastNotificationDate）
  /// // 添加这个静态变量
  static bool _hasCheckedOverdueToday = false;

  static Future<void> checkAndProcessOverdueBills(String userId) async {
    // 如果本次运行已经检查过，直接跳过
    if (_hasCheckedOverdueToday) return;

    // 可以在这里加一个简单的防抖打印
    print("Checking for overdue bills...");

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. 获取该用户所有 'unpaid' 或 'overdue' 的账单
    final querySnapshot = await _db
        .collection('bills')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['unpaid', 'overdue'])
        .get();

    final batch = _db.batch();
    bool hasUpdates = false;

    for (var doc in querySnapshot.docs) {
      final bill = BillModel.fromMap(doc.data(), doc.id);

      // 只有当真正过期时才处理
      if (now.isAfter(bill.dueDate)) {
        Map<String, dynamic> updates = {};

        // --- A. 状态更新 ---
        if (bill.status != 'overdue') {
          updates['status'] = 'overdue';
        }

        // --- B. 罚金计算 (每周递增 5%) ---
        final overdueDays = now
            .difference(bill.dueDate)
            .inDays;
        // 向上取整，例如逾期1天算第1周，逾期8天算第2周
        // 如果你想满一周才罚，可以用 floor()
        final overdueWeeks = (overdueDays / 7).ceil();

        if (overdueWeeks > 0) {
          const double penaltyRatePerWeek = 0.05; // 5%
          final newPenalty = bill.amount * penaltyRatePerWeek * overdueWeeks;

          // 只有罚金增加时才更新（防止数据抖动）
          if (newPenalty > bill.penalty) {
            updates['penalty'] = newPenalty;
          }
        }

        // --- C. 每日通知 ---
        bool shouldNotify = true;
        if (bill.lastNotificationDate != null) {
          final last = bill.lastNotificationDate!;
          // 如果今天是同一年同一月同一天，就不再通知
          if (last.year == today.year && last.month == today.month &&
              last.day == today.day) {
            shouldNotify = false;
          }
        }

        if (shouldNotify) {
          updates['lastNotificationDate'] = Timestamp.fromDate(now);

          // 创建通知
          final notificationRef = _db.collection('notifications').doc();
          batch.set(notificationRef, {
            'userId': userId,
            'title': 'Overdue Alert: ${bill.title}',
            'message': 'Your bill is overdue by $overdueDays days. Late fees have been applied. Please pay immediately.',
            'type': 'bill_overdue', // 前端可以根据这个类型跳转
            'relatedId': bill.id,
            'isRead': false,
            'createdAt': Timestamp.now(),
          });
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates) {
      await batch.commit();
      print('Overdue bills processed for user $userId');
    }
  }

  /// 获取逾期账单流 (专门用于 Overdue Tab)
  static Stream<List<BillModel>> getUserOverdueBillsStream(String userId) {
    return _db
        .collection('bills')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'overdue')
        .orderBy('dueDate', descending: false) // 最早过期的排前面，越紧急越靠前
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BillModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }


  static Stream<List<UserNotificationModel>> getUserNotificationsStream(
      String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserNotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// 获取未读通知数量流 (用于显示红点)
  static Stream<int> getUnreadNotificationCountStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 标记单条通知为已读
  static Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update(
        {'isRead': true});
  }

  /// 标记所有通知为已读
  static Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _db.batch();
    final querySnapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    if (querySnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// 删除通知
  static Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // 在 FirestoreService 类中添加以下方法

  /// Increment like count for an announcement
  static Future<void> incrementAnnouncementLike(String announcementId) async {
    // 使用 FieldValue.increment 确保原子操作，防止并发冲突
    await _db.collection('announcements').doc(announcementId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  /// Get single announcement stream (for detail screen live updates)
  static Stream<AnnouncementModel> getAnnouncementStream(String id) {
    return _db.collection('announcements').doc(id).snapshots().map((doc) {
      return AnnouncementModel.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Create a new package document AND notify the user
  static Future<String> createPackage(Map<String, dynamic> data) async {
    // 1. 初始化 Batch (批量处理)
    final batch = _db.batch();

    // 2. 准备包裹数据 (Packages)
    final packageRef = _db.collection('packages').doc();
    final Map<String, dynamic> payload = Map.from(data);
    // Force location to be the fixed value
    payload['location'] = 'Management Office';

    // 确保时间格式正确
    if (payload['arrivedAt'] is DateTime) {
      payload['arrivedAt'] =
          Timestamp.fromDate(payload['arrivedAt'] as DateTime);
    }
    if (payload.containsKey('collectedAt') &&
        payload['collectedAt'] is DateTime) {
      payload['collectedAt'] =
          Timestamp.fromDate(payload['collectedAt'] as DateTime);
    }

    // 将包裹写入操作加入 batch
    batch.set(packageRef, payload);

    // 3. 准备通知数据 (Notifications) - 这里是新增的逻辑
    final notificationRef = _db.collection('notifications').doc();
    final String userId = payload['userId']; // 获取对应的住户ID
    final String courier = payload['courier'] ?? 'Unknown';
    final String trackingNumber = payload['trackingNumber'] ?? '';

    // 创建通知文档
    batch.set(notificationRef, {
      'userId': userId,
      'title': 'New Parcel Arrived',
      'message': 'A new parcel from $courier has arrived. Tracking: $trackingNumber',
      'type': 'package', // 类型设为 package
      'relatedId': packageRef.id, // 关联包裹ID
      'isRead': false,
      'createdAt': Timestamp.now(),
    });

    // 4. 一次性提交所有操作
    await batch.commit();

    return packageRef.id;
  }

  // --- 新增/修改 Repair 相关方法 ---

  /// 用户/系统：取消维修申请
  static Future<void> cancelRepair(String repairId, {String? userId, bool isAuto = false}) async {
    // 如果是自动取消，需要 userId 来发通知
    final batch = _db.batch();
    final repairRef = _db.collection('repairs').doc(repairId);

    batch.update(repairRef, {
      'status': 'canceled',
      'completedAt': Timestamp.now(), // 视为结束
    });

    if (isAuto && userId != null) {
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': userId,
        'title': 'Request Auto-Canceled',
        'message': 'Your request was automatically canceled as it was not processed within 5 days.',
        'type': 'repair_update',
        'relatedId': repairId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  /// 用户：确认维修完成 (必须在 in_progress 状态下)
  static Future<void> completeRepairByUser(String repairId) async {
    await _db.collection('repairs').doc(repairId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  /// 系统：检查自动取消 (超过5天未开启的 Pending 任务)
  /// 建议在 AdminRepairsScreen 初始化时调用
  static Future<void> checkAutoCancelRepairs() async {
    final now = DateTime.now();
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    final query = await _db.collection('repairs')
        .where('status', isEqualTo: 'pending')
        .where('createdAt', isLessThan: Timestamp.fromDate(fiveDaysAgo))
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final userId = data['userId'];
      // 执行自动取消
      await cancelRepair(doc.id, userId: userId, isAuto: true);
    }
  }


  // ================= NEW: 工人专用逻辑 (Workers Collection) =================

  // 1. 获取工人列表 (从 'workers' 集合读取)
  static Stream<List<UserModel>> getWorkersStream() {
    return _db.collection('workers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // 强行把 role 设为 worker，以防万一
        data['role'] = 'worker';
        return UserModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // 为了兼容 AdminRepairsScreen 的 Future 调用 (如果那边还没改)
  static Future<List<UserModel>> getWorkers() async {
    final snapshot = await _db.collection('workers').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  // 2. 添加新工人 (直接写库，不需要 Auth)
  static Future<void> addWorker(Map<String, dynamic> data) async {
    try {
      // 自动生成 ID
      final docRef = _db.collection('workers').doc();

      final workerData = {
        ...data,
        'id': docRef.id,
        'role': 'worker', // 标记角色
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(workerData);
    } catch (e) {
      print("Error adding worker: $e");
      rethrow;
    }
  }

  // 3. 删除工人
  static Future<void> deleteWorker(String workerId) async {
    try {
      await _db.collection('workers').doc(workerId).delete();
    } catch (e) {
      print("Error deleting worker: $e");
      rethrow;
    }
  }

  /// Update worker document in 'workers' collection
  static Future<void> updateWorker(String workerId, Map<String, dynamic> data) async {
    await _db.collection('workers').doc(workerId).update(data);
  }

  // 在 FirestoreService 类中添加/更新这两个方法

  // 1. 分配维修人员 (确保 status 变更为 in_progress)
  static Future<void> assignRepair({
    required String repairId,
    required String userId,
    required String workerId,
    required String workerName,
    required DateTime repairDate,
  }) async {
    final batch = _db.batch();

    // 更新维修单
    final repairRef = _db.collection('repairs').doc(repairId);
    batch.update(repairRef, {
      'workerId': workerId,
      'workerName': workerName,
      'repairDate': Timestamp.fromDate(repairDate),
      'status': 'in_progress', // <--- 关键：确保这里写了 'in_progress'
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 发送通知 (App内通知)
    final notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': userId,
      'title': 'Request Scheduled',
      'message': 'Worker $workerName assigned. Date: ${repairDate.toString().split(' ')[0]}',
      'type': 'repair_update',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': repairId,
    });

    await batch.commit();
  }

  // 2. 拒绝维修请求 (新增方法)
  static Future<void> rejectRepair({
    required String repairId,
    required String userId,
    required String reason,
  }) async {
    final batch = _db.batch();

    final repairRef = _db.collection('repairs').doc(repairId);
    batch.update(repairRef, {
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': userId,
      'title': 'Request Rejected',
      'message': 'Your request was rejected: $reason',
      'type': 'repair_update',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': repairId,
    });

    await batch.commit();
  }
}



