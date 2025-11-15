import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

/// Firestore Migration Utilities
/// Run these once to update existing data when schema changes
class FirestoreMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add mutedGroupChatIds field to all existing users
  /// Run this once if you have existing users without this field
  static Future<void> addMutedGroupChatIdsToUsers() async {
    try {
      print('Starting migration: Adding mutedGroupChatIds to all users...');

      // Get all users
      QuerySnapshot usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      int updated = 0;
      int alreadyHasField = 0;

      // Update each user
      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if the field already exists
        if (!data.containsKey('mutedGroupChatIds')) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(doc.id)
              .update({
            'mutedGroupChatIds': [],
          });
          updated++;
          print('✅ Updated user: ${data['email']}');
        } else {
          alreadyHasField++;
        }
      }

      print('');
      print('Migration completed!');
      print('Updated: $updated users');
      print('Already had field: $alreadyHasField users');
      print('Total: ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Run all pending migrations
  static Future<void> runAllMigrations() async {
    print('🔄 Running all Firestore migrations...');
    print('');

    try {
      // Add new migrations here as needed
      await addMutedGroupChatIdsToUsers();

      print('');
      print('✅ All migrations completed successfully!');
    } catch (e) {
      print('❌ Migration error: $e');
      rethrow;
    }
  }
}
