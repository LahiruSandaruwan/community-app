import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bookmark a message
  Future<void> addBookmark({
    required String userId,
    required String groupChatId,
    required String messageId,
    String? note,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'groupChatId': groupChatId,
        'bookmarkedAt': FieldValue.serverTimestamp(),
        'note': note,
      });
    } catch (e) {
      throw 'Failed to bookmark message: $e';
    }
  }

  // Remove bookmark
  Future<void> removeBookmark({
    required String userId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw 'Failed to remove bookmark: $e';
    }
  }

  // Check if message is bookmarked
  Future<bool> isBookmarked({
    required String userId,
    required String messageId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(messageId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all bookmarked messages for a user
  Stream<List<Map<String, dynamic>>> getBookmarks({
    required String userId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> bookmarks = [];

      for (var bookmarkDoc in snapshot.docs) {
        Map<String, dynamic> bookmarkData =
            bookmarkDoc.data();

        final groupChatId = bookmarkData['groupChatId'];
        final messageId = bookmarkData['messageId'];

        // Fetch the actual message
        try {
          final messageDoc = await _firestore
              .collection(AppConstants.groupChatsCollection)
              .doc(groupChatId)
              .collection(AppConstants.messagesCollection)
              .doc(messageId)
              .get();

          if (messageDoc.exists) {
            final message = MessageModel.fromFirestore(messageDoc);
            bookmarks.add({
              'bookmarkId': bookmarkDoc.id,
              'message': message,
              'groupChatId': groupChatId,
              'bookmarkedAt': bookmarkData['bookmarkedAt'],
              'note': bookmarkData['note'],
            });
          }
        } catch (e) {
          print('Failed to fetch bookmarked message: $e');
        }
      }

      return bookmarks;
    });
  }
}
