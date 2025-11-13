import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  Future<MessageModel> sendMessage({
    required String groupChatId,
    required String senderId,
    required String senderName,
    String? senderProfileUrl,
    required String content,
    String messageType = 'text',
    String? replyToMessageId,
  }) async {
    try {
      DocumentReference messageRef = _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .doc();

      MessageModel message = MessageModel(
        id: messageRef.id,
        groupChatId: groupChatId,
        senderId: senderId,
        senderName: senderName,
        senderProfileUrl: senderProfileUrl,
        content: content,
        messageType: messageType,
        timestamp: DateTime.now(),
        readBy: [senderId], // Sender has read the message
        replyToMessageId: replyToMessageId,
      );

      await messageRef.set(message.toFirestore());

      // Update group chat's last message
      await _updateGroupChatLastMessage(
        groupChatId: groupChatId,
        lastMessage: content,
        lastMessageSenderId: senderId,
      );

      return message;
    } catch (e) {
      throw 'Failed to send message: $e';
    }
  }

  // Get messages for a group chat (with pagination)
  Stream<List<MessageModel>> getMessages({
    required String groupChatId,
    int limit = 50,
  }) {
    return _firestore
        .collection(AppConstants.groupChatsCollection)
        .doc(groupChatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Mark message as read
  Future<void> markMessageAsRead({
    required String groupChatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      // Silently fail - not critical
      print('Failed to mark message as read: $e');
    }
  }

  // Mark all messages in a group chat as read
  Future<void> markAllMessagesAsRead({
    required String groupChatId,
    required String userId,
  }) async {
    try {
      // Get unread messages
      QuerySnapshot unreadMessages = await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .where('readBy', whereNotIn: [
        [userId]
      ]).get();

      // Mark each as read
      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
      await batch.commit();

      // Reset unread count for user
      await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      print('Failed to mark all messages as read: $e');
    }
  }

  // Pin/unpin a message
  Future<void> togglePinMessage({
    required String groupChatId,
    required String messageId,
    required bool pin,
  }) async {
    try {
      // Update message pin status
      await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({'isPinned': pin});

      // Update group chat's pinned messages list
      await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .update({
        'pinnedMessageIds': pin
            ? FieldValue.arrayUnion([messageId])
            : FieldValue.arrayRemove([messageId]),
      });
    } catch (e) {
      throw 'Failed to ${pin ? 'pin' : 'unpin'} message: $e';
    }
  }

  // Get pinned messages
  Future<List<MessageModel>> getPinnedMessages(String groupChatId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .where('isPinned', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get pinned messages: $e';
    }
  }

  // Delete a message (soft delete by updating content)
  Future<void> deleteMessage({
    required String groupChatId,
    required String messageId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'content': 'This message was deleted',
        'metadata': {'deleted': true, 'deletedAt': FieldValue.serverTimestamp()},
      });
    } catch (e) {
      throw 'Failed to delete message: $e';
    }
  }

  // Set typing indicator
  Future<void> setTypingIndicator({
    required String groupChatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      // Store typing status in a separate collection for real-time updates
      DocumentReference typingRef = _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection('typing')
          .doc(userId);

      if (isTyping) {
        await typingRef.set({
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      // Silently fail - not critical
      print('Failed to set typing indicator: $e');
    }
  }

  // Get typing users
  Stream<List<String>> getTypingUsers({
    required String groupChatId,
    required String currentUserId,
  }) {
    return _firestore
        .collection(AppConstants.groupChatsCollection)
        .doc(groupChatId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      List<String> typingUserIds = [];
      for (var doc in snapshot.docs) {
        if (doc.id != currentUserId) {
          // Exclude current user
          Map<String, dynamic> data = doc.data();
          if (data['isTyping'] == true) {
            typingUserIds.add(doc.id);
          }
        }
      }
      return typingUserIds;
    });
  }

  // Get unread message count for a user in a group chat
  Future<int> getUnreadCount({
    required String groupChatId,
    required String userId,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .get();

      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        MessageModel message = MessageModel.fromFirestore(doc);
        if (!message.isReadBy(userId)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Update group chat's last message
  Future<void> _updateGroupChatLastMessage({
    required String groupChatId,
    required String lastMessage,
    required String lastMessageSenderId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .update({
        'lastMessage': lastMessage.length > 50
            ? '${lastMessage.substring(0, 50)}...'
            : lastMessage,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': lastMessageSenderId,
      });
    } catch (e) {
      print('Failed to update last message: $e');
    }
  }

  // Search messages in a group chat
  Future<List<MessageModel>> searchMessages({
    required String groupChatId,
    required String query,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that gets all messages and filters client-side
      // For production, consider using Algolia or ElasticSearch
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.groupChatsCollection)
          .doc(groupChatId)
          .collection(AppConstants.messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      List<MessageModel> allMessages =
          snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();

      // Filter messages containing the query (case-insensitive)
      return allMessages
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw 'Failed to search messages: $e';
    }
  }
}
