import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/mock_data.dart';
import 'firestore_service.dart';

class DataMigrationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Migrate mock bills data to Firestore
  static Future<void> migrateBillsToFirestore() async {
    print('Starting bills migration to Firestore...');

    try {
      // Get users with resident role (equivalent to "user" as mentioned by user)
      final residentUsers = MockData.users.values
          .where((user) => user.role == 'resident')
          .toList();

      if (residentUsers.isEmpty) {
        print('No resident users found for migration');
        return;
      }

      // Use the first resident user
      final residentUser = residentUsers.first;
      print('Using resident user: ${residentUser.name} (ID: ${residentUser.id})');

      // Migrate each bill
      for (final bill in MockData.bills) {
        final billData = {
          'userId': residentUser.id,
          'payerName': residentUser.name,
          'propertySimpleAddress': residentUser.propertySimpleAddress,
          'title': bill.title,
          'description': bill.description,
          'amount': bill.amount,
          'dueDate': Timestamp.fromDate(bill.dueDate),
          'billingDate': Timestamp.fromDate(bill.billingDate),
          'status': bill.status,
          'category': bill.category,
          'paymentId': bill.paymentId,
        };

        final docRef = await _db.collection('bills').add(billData);
        print('Migrated bill: ${bill.title} (ID: ${docRef.id})');
      }

      print('Bills migration completed successfully!');
    } catch (e) {
      print('Error migrating bills: $e');
      rethrow;
    }
  }

  /// Check if bills collection already has data
  static Future<bool> hasExistingBills() async {
    final snapshot = await _db.collection('bills').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Clear all bills from Firestore (for testing/reset)
  static Future<void> clearBillsCollection() async {
    final snapshot = await _db.collection('bills').get();
    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('Cleared all bills from Firestore');
  }

  /// Migrate all bills and user IDs to a selected user
  /// This consolidates all data to use a single user's identity
  static Future<void> migrateAllDataToSelectedUser(String selectedUserId) async {
    print('Starting data migration to selected user...');

    try {
      await FirestoreService.migrateAllDataToUser(selectedUserId);
      print('Data migration completed successfully!');
    } catch (e) {
      print('Error during data migration: $e');
      rethrow;
    }
  }

  /// Sync user avatar data to Firebase
  /// Ensures all users have their avatar URLs properly stored in Firestore
  static Future<void> syncUserAvatarsToFirebase() async {
    print('Starting avatar data sync to Firebase...');

    try {
      // Get all users from Firestore
      final usersSnapshot = await _db.collection('users').get();
      final users = usersSnapshot.docs;

      if (users.isEmpty) {
        print('No users found in Firestore');
        return;
      }

      print('Found ${users.length} users to check for avatar sync');

      int updatedCount = 0;

      // Check each user for avatar data
      for (final userDoc in users) {
        final userData = userDoc.data();
        final userId = userDoc.id;

        // Check if avatar field exists and is valid
        final avatar = userData['avatar'];

        // If avatar is null or empty, set it to null explicitly
        if (avatar == null || avatar.toString().isEmpty) {
          if (userData.containsKey('avatar') && userData['avatar'] != null) {
            // Update to explicitly set avatar to null
            await userDoc.reference.update({'avatar': null});
            updatedCount++;
            print('Cleared invalid avatar for user: $userId');
          }
        } else {
          // Avatar exists, validate the URL format
          final avatarUrl = avatar.toString();
          if (!avatarUrl.startsWith('http://') && !avatarUrl.startsWith('https://')) {
            // Invalid URL format, clear it
            await userDoc.reference.update({'avatar': null});
            updatedCount++;
            print('Cleared invalid avatar URL for user: $userId');
          } else {
            print('Avatar URL valid for user: $userId');
          }
        }
      }

      // Also sync workers collection
      final workersSnapshot = await _db.collection('workers').get();
      final workers = workersSnapshot.docs;

      print('Found ${workers.length} workers to check for avatar sync');

      for (final workerDoc in workers) {
        final workerData = workerDoc.data();
        final workerId = workerDoc.id;

        final avatar = workerData['avatar'];
        if (avatar != null && avatar.toString().isNotEmpty) {
          final avatarUrl = avatar.toString();
          if (!avatarUrl.startsWith('http://') && !avatarUrl.startsWith('https://')) {
            await workerDoc.reference.update({'avatar': null});
            updatedCount++;
            print('Cleared invalid avatar URL for worker: $workerId');
          }
        }
      }

      print('Avatar sync completed! Updated $updatedCount records');
    } catch (e) {
      print('Error syncing avatar data: $e');
      rethrow;
    }
  }

  /// Get avatar sync status
  static Future<Map<String, dynamic>> getAvatarSyncStatus() async {
    try {
      final usersSnapshot = await _db.collection('users').get();
      final workersSnapshot = await _db.collection('workers').get();

      int totalUsers = usersSnapshot.docs.length;
      int totalWorkers = workersSnapshot.docs.length;

      int usersWithAvatars = 0;
      int workersWithAvatars = 0;

      for (final doc in usersSnapshot.docs) {
        if (doc.data()['avatar'] != null && doc.data()['avatar'].toString().isNotEmpty) {
          usersWithAvatars++;
        }
      }

      for (final doc in workersSnapshot.docs) {
        if (doc.data()['avatar'] != null && doc.data()['avatar'].toString().isNotEmpty) {
          workersWithAvatars++;
        }
      }

      return {
        'totalUsers': totalUsers,
        'totalWorkers': totalWorkers,
        'usersWithAvatars': usersWithAvatars,
        'workersWithAvatars': workersWithAvatars,
        'syncComplete': true,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'syncComplete': false,
      };
    }
  }
}
