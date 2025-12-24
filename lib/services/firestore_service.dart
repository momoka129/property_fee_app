import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../models/bill_model.dart';
import '../models/user_model.dart';
import '../models/package_model.dart';
import '../models/repair_model.dart';
import '../models/bank_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns a stream of announcements ordered by publishedAt (desc).
  static Stream<List<AnnouncementModel>> announcementsStream({int? limit}) {
    Query query = _db.collection('announcements').orderBy('publishedAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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
      payload['publishedAt'] = Timestamp.fromDate(payload['publishedAt'] as DateTime);
    }
    if (payload.containsKey('expireAt') && payload['expireAt'] is DateTime) {
      payload['expireAt'] = Timestamp.fromDate(payload['expireAt'] as DateTime);
    }

    // Expect 'author' and 'isPinned' keys directly from client; do not write legacy 'createdBy'/'pinned' or 'communityId'.

    await docRef.set(payload);
    return docRef.id;
  }

  /// Admin: update an existing announcement
  static Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    final docRef = _db.collection('announcements').doc(id);
    final Map<String, dynamic> payload = Map.from(data);
    if (payload['publishedAt'] is DateTime) {
      payload['publishedAt'] = Timestamp.fromDate(payload['publishedAt'] as DateTime);
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
  static Stream<List<BillModel>> getUserBillsByPropertyAddressStream(String propertySimpleAddress) {
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
      payload['billingDate'] = Timestamp.fromDate(payload['billingDate'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update bill status
  static Future<void> updateBillStatus(String billId, String status, {String? paymentId}) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (paymentId != null) {
      updateData['paymentId'] = paymentId;
    }
    await _db.collection('bills').doc(billId).update(updateData);
  }

  /// Update entire bill document (admin)
  static Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    final docRef = _db.collection('bills').doc(billId);
    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp
    if (payload['dueDate'] is DateTime) {
      payload['dueDate'] = Timestamp.fromDate(payload['dueDate'] as DateTime);
    }
    if (payload['billingDate'] is DateTime) {
      payload['billingDate'] = Timestamp.fromDate(payload['billingDate'] as DateTime);
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
    final querySnapshot = await _db.collection('accounts').where('role', isEqualTo: 'user').get();
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
      final selectedUserDoc = await _db.collection('accounts').doc(selectedUserId).get();
      if (!selectedUserDoc.exists) {
        throw Exception('Selected user does not exist');
      }
      final selectedUser = UserModel.fromMap(selectedUserDoc.data()!, selectedUserDoc.id);

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

      print('Successfully migrated all bills to user: ${selectedUser.name} (${selectedUser.id})');
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

  /// Create a new package document
  static Future<String> createPackage(Map<String, dynamic> data) async {
    final docRef = _db.collection('packages').doc();

    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp
    if (payload['arrivedAt'] is DateTime) {
      payload['arrivedAt'] = Timestamp.fromDate(payload['arrivedAt'] as DateTime);
    }
    if (payload.containsKey('collectedAt') && payload['collectedAt'] is DateTime) {
      payload['collectedAt'] = Timestamp.fromDate(payload['collectedAt'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update package status
  static Future<void> updatePackageStatus(String packageId, String status, {DateTime? collectedAt}) async {
    final Map<String, dynamic> updateData = {'status': status};
    if (collectedAt != null) {
      updateData['collectedAt'] = Timestamp.fromDate(collectedAt);
    }
    await _db.collection('packages').doc(packageId).update(updateData);
  }

  /// Update entire package document
  static Future<void> updatePackage(String packageId, Map<String, dynamic> data) async {
    final docRef = _db.collection('packages').doc(packageId);
    final Map<String, dynamic> payload = Map.from(data);

    // Convert DateTime -> Timestamp
    if (payload['arrivedAt'] is DateTime) {
      payload['arrivedAt'] = Timestamp.fromDate(payload['arrivedAt'] as DateTime);
    }
    if (payload.containsKey('collectedAt') && payload['collectedAt'] is DateTime) {
      payload['collectedAt'] = Timestamp.fromDate(payload['collectedAt'] as DateTime);
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
      payload['createdAt'] = Timestamp.fromDate(payload['createdAt'] as DateTime);
    }
    if (payload.containsKey('completedAt') && payload['completedAt'] is DateTime) {
      payload['completedAt'] = Timestamp.fromDate(payload['completedAt'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update repair status (admin)
  static Future<void> updateRepairStatus(String repairId, String status, {DateTime? completedAt}) async {
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
      payload['paymentDate'] = Timestamp.fromDate(payload['paymentDate'] as DateTime);
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
      payload['createdAt'] = Timestamp.fromDate(payload['createdAt'] as DateTime);
    }

    await docRef.set(payload);
    return docRef.id;
  }

  /// Update bank account
  static Future<void> updateBank(String bankId, Map<String, dynamic> data) async {
    await _db.collection('banks').doc(bankId).update(data);
  }

  /// Delete bank account
  static Future<void> deleteBank(String bankId) async {
    await _db.collection('banks').doc(bankId).delete();
  }

  /// Update user profile
  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('accounts').doc(userId).update(data);
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
    final querySnapshot = await _db.collection('accounts').where('uid', isEqualTo: uid).where('role', isEqualTo: 'admin').get();
    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
    }
    return null;
  }

  /// Get all admins
  static Future<List<UserModel>> getAdmins() async {
    final querySnapshot = await _db.collection('accounts').where('role', isEqualTo: 'admin').get();
    return querySnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id);
    }).toList();
  }

  /// Check if an address already exists in the accounts collection
  static Future<bool> checkAddressExists(String propertySimpleAddress, {String? excludeUserId}) async {
    Query query = _db.collection('accounts').where('propertySimpleAddress', isEqualTo: propertySimpleAddress);

    final querySnapshot = await query.get();

    // If excluding a user ID (for updates), filter out that user
    if (excludeUserId != null) {
      final filteredDocs = querySnapshot.docs.where((doc) => doc.id != excludeUserId);
      return filteredDocs.isNotEmpty;
    }

    return querySnapshot.docs.isNotEmpty;
  }
}


