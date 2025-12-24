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
}
