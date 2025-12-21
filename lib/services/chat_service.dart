import 'package:pocketbase/pocketbase.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class ChatService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<List<MessageModel>>> _messageStreams = {};
  final Map<String, StreamController<List<String>>> _typingStreams = {};

  // Send a message
  Future<MessageModel> sendMessage({
    required String groupChatId,
    required String senderId,
    required String senderName,
    String? senderProfileUrl,
    required String content,
    String messageType = 'text',
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();

      final messageData = {
        'groupChatId': groupChatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderProfileUrl': senderProfileUrl ?? '',
        'content': content,
        'messageType': messageType,
        'timestamp': now.toIso8601String(),
        'readBy': [senderId], // Sender has read the message
        'isPinned': false,
        'replyToMessageId': replyToMessageId ?? '',
        'metadata': metadata,
        'reactions': {},
      };

      final record = await _pb.collection(AppConstants.messagesCollection).create(
        body: messageData,
      );

      // Update group chat's last message
      await _updateGroupChatLastMessage(
        groupChatId: groupChatId,
        lastMessage: content,
        lastMessageSenderId: senderId,
      );

      return MessageModel.fromPocketBase(record);
    } on ClientException catch (e) {
      throw 'Failed to send message: ${e.response}';
    } catch (e) {
      throw 'Failed to send message: $e';
    }
  }

  // Get messages for a group chat (with pagination)
  Stream<List<MessageModel>> getMessages({
    required String groupChatId,
    int limit = 50,
  }) {
    // Create or reuse stream controller for this group chat
    final streamKey = 'messages_$groupChatId';

    if (!_messageStreams.containsKey(streamKey)) {
      final controller = StreamController<List<MessageModel>>.broadcast(
        onCancel: () {
          _messageStreams.remove(streamKey);
        },
      );
      _messageStreams[streamKey] = controller;

      // Initial fetch
      _fetchAndEmitMessages(groupChatId, limit, controller);

      // Subscribe to real-time updates
      _pb.collection(AppConstants.messagesCollection).subscribe(
        '*',
        (e) {
          // Refetch messages when any change occurs
          _fetchAndEmitMessages(groupChatId, limit, controller);
        },
        filter: 'groupChatId = "$groupChatId"',
      );
    }

    return _messageStreams[streamKey]!.stream;
  }

  // Helper method to fetch and emit messages
  Future<void> _fetchAndEmitMessages(
    String groupChatId,
    int limit,
    StreamController<List<MessageModel>> controller,
  ) async {
    try {
      final records = await _pb.collection(AppConstants.messagesCollection).getList(
        page: 1,
        perPage: limit,
        sort: '-timestamp',
        filter: 'groupChatId = "$groupChatId"',
      );

      final messages = records.items
          .map((record) => MessageModel.fromPocketBase(record))
          .toList();

      if (!controller.isClosed) {
        controller.add(messages);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead({
    required String groupChatId,
    required String messageId,
    required String userId,
  }) async {
    try {
      // Fetch current message
      final message = await _pb.collection(AppConstants.messagesCollection).getOne(messageId);
      final readBy = List<String>.from(message.data['readBy'] ?? []);

      // Add userId if not already present
      if (!readBy.contains(userId)) {
        readBy.add(userId);

        await _pb.collection(AppConstants.messagesCollection).update(
          messageId,
          body: {'readBy': readBy},
        );
      }
    } on ClientException catch (e) {
      if (e.statusCode != 404) {
        throw 'Failed to mark message as read: ${e.response['message'] ?? e.toString()}';
      }
      // Ignore 404 - message may have been deleted
    } catch (e) {
      throw 'Failed to mark message as read: $e';
    }
  }

  // Mark all messages in a group chat as read
  Future<void> markAllMessagesAsRead({
    required String groupChatId,
    required String userId,
  }) async {
    try {
      // Get all messages in the group chat
      final messages = await _pb.collection(AppConstants.messagesCollection).getFullList(
        filter: 'groupChatId = "$groupChatId"',
      );

      // Update each message that hasn't been read by this user
      List<String> failedMessageIds = [];
      for (var messageRecord in messages) {
        final readBy = List<String>.from(messageRecord.data['readBy'] ?? []);

        if (!readBy.contains(userId)) {
          readBy.add(userId);

          try {
            await _pb.collection(AppConstants.messagesCollection).update(
              messageRecord.id,
              body: {'readBy': readBy},
            );
          } catch (e) {
            failedMessageIds.add(messageRecord.id);
          }
        }
      }

      // Reset unread count for user in group chat
      try {
        final groupChat = await _pb.collection(AppConstants.groupChatsCollection).getOne(groupChatId);
        final unreadCounts = Map<String, dynamic>.from(groupChat.data['unreadCounts'] ?? {});
        unreadCounts[userId] = 0;

        await _pb.collection(AppConstants.groupChatsCollection).update(
          groupChatId,
          body: {'unreadCounts': unreadCounts},
        );
      } on ClientException catch (e) {
        if (e.statusCode != 404) {
          throw 'Failed to reset unread count: ${e.response['message'] ?? e.toString()}';
        }
        // Ignore 404 - group chat may have been deleted
      } catch (e) {
        throw 'Failed to reset unread count: $e';
      }

      if (failedMessageIds.isNotEmpty) {
        throw 'Failed to mark ${failedMessageIds.length} message(s) as read';
      }
    } on ClientException catch (e) {
      throw 'Failed to mark all messages as read: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to mark all messages as read: $e';
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
      await _pb.collection(AppConstants.messagesCollection).update(
        messageId,
        body: {'isPinned': pin},
      );

      // Update group chat's pinned messages list
      final groupChat = await _pb.collection(AppConstants.groupChatsCollection).getOne(groupChatId);
      final pinnedMessageIds = List<String>.from(groupChat.data['pinnedMessageIds'] ?? []);

      if (pin) {
        if (!pinnedMessageIds.contains(messageId)) {
          pinnedMessageIds.add(messageId);
        }
      } else {
        pinnedMessageIds.remove(messageId);
      }

      await _pb.collection(AppConstants.groupChatsCollection).update(
        groupChatId,
        body: {'pinnedMessageIds': pinnedMessageIds},
      );
    } on ClientException catch (e) {
      throw 'Failed to ${pin ? 'pin' : 'unpin'} message: ${e.response}';
    } catch (e) {
      throw 'Failed to ${pin ? 'pin' : 'unpin'} message: $e';
    }
  }

  // Get pinned messages
  Future<List<MessageModel>> getPinnedMessages(String groupChatId) async {
    try {
      final records = await _pb.collection(AppConstants.messagesCollection).getFullList(
        filter: 'groupChatId = "$groupChatId" && isPinned = true',
        sort: '-timestamp',
      );

      return records
          .map((record) => MessageModel.fromPocketBase(record))
          .toList();
    } on ClientException catch (e) {
      throw 'Failed to get pinned messages: ${e.response}';
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
      await _pb.collection(AppConstants.messagesCollection).update(
        messageId,
        body: {
          'content': 'This message was deleted',
          'metadata': {
            'deleted': true,
            'deletedAt': DateTime.now().toIso8601String(),
          },
        },
      );
    } on ClientException catch (e) {
      throw 'Failed to delete message: ${e.response}';
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
      // Use a separate collection for typing indicators (since PocketBase doesn't support subcollections)
      // Collection name: 'typing' with fields: groupChatId, userId, isTyping, timestamp

      if (isTyping) {
        // Try to find existing typing record
        try {
          final existingRecords = await _pb.collection('typing').getFullList(
            filter: 'groupChatId = "$groupChatId" && userId = "$userId"',
          );

          if (existingRecords.isNotEmpty) {
            // Update existing record
            await _pb.collection('typing').update(
              existingRecords.first.id,
              body: {
                'isTyping': true,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } else {
            // Create new record
            await _pb.collection('typing').create(
              body: {
                'groupChatId': groupChatId,
                'userId': userId,
                'isTyping': true,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        } catch (e) {
          // If not found, create new
          await _pb.collection('typing').create(
            body: {
              'groupChatId': groupChatId,
              'userId': userId,
              'isTyping': true,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      } else {
        // Delete typing record
        try {
          final existingRecords = await _pb.collection('typing').getFullList(
            filter: 'groupChatId = "$groupChatId" && userId = "$userId"',
          );

          for (var record in existingRecords) {
            await _pb.collection('typing').delete(record.id);
          }
        } catch (e) {
          // Ignore if not found
        }
      }
    } on ClientException catch (e) {
      throw 'Failed to set typing indicator: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to set typing indicator: $e';
    }
  }

  // Get typing users
  Stream<List<String>> getTypingUsers({
    required String groupChatId,
    required String currentUserId,
  }) {
    // Create or reuse stream controller for typing indicators
    final streamKey = 'typing_$groupChatId';

    if (!_typingStreams.containsKey(streamKey)) {
      final controller = StreamController<List<String>>.broadcast(
        onCancel: () {
          _typingStreams.remove(streamKey);
        },
      );
      _typingStreams[streamKey] = controller;

      // Initial fetch
      _fetchAndEmitTypingUsers(groupChatId, currentUserId, controller);

      // Subscribe to real-time updates
      _pb.collection('typing').subscribe(
        '*',
        (e) {
          _fetchAndEmitTypingUsers(groupChatId, currentUserId, controller);
        },
        filter: 'groupChatId = "$groupChatId"',
      );
    }

    return _typingStreams[streamKey]!.stream;
  }

  // Helper method to fetch and emit typing users
  Future<void> _fetchAndEmitTypingUsers(
    String groupChatId,
    String currentUserId,
    StreamController<List<String>> controller,
  ) async {
    try {
      final records = await _pb.collection('typing').getFullList(
        filter: 'groupChatId = "$groupChatId" && isTyping = true',
      );

      final typingUserIds = records
          .map((record) => record.getStringValue('userId'))
          .where((userId) => userId != currentUserId) // Exclude current user
          .toList();

      if (!controller.isClosed) {
        controller.add(typingUserIds);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Get unread message count for a user in a group chat
  Future<int> getUnreadCount({
    required String groupChatId,
    required String userId,
  }) async {
    try {
      final messages = await _pb.collection(AppConstants.messagesCollection).getFullList(
        filter: 'groupChatId = "$groupChatId" && senderId != "$userId"',
      );

      int unreadCount = 0;
      for (var messageRecord in messages) {
        final message = MessageModel.fromPocketBase(messageRecord);
        if (!message.isReadBy(userId)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } on ClientException catch (e) {
      throw 'Failed to get unread count: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to get unread count: $e';
    }
  }

  // Update group chat's last message
  Future<void> _updateGroupChatLastMessage({
    required String groupChatId,
    required String lastMessage,
    required String lastMessageSenderId,
  }) async {
    try {
      await _pb.collection(AppConstants.groupChatsCollection).update(
        groupChatId,
        body: {
          'lastMessage': lastMessage.length > 50
              ? '${lastMessage.substring(0, 50)}...'
              : lastMessage,
          'lastMessageAt': DateTime.now().toIso8601String(),
          'lastMessageSenderId': lastMessageSenderId,
        },
      );
    } on ClientException catch (e) {
      if (e.statusCode != 404) {
        throw 'Failed to update last message: ${e.response['message'] ?? e.toString()}';
      }
      // Ignore 404 - group chat may have been deleted
    } catch (e) {
      throw 'Failed to update last message: $e';
    }
  }

  // Search messages in a group chat
  Future<List<MessageModel>> searchMessages({
    required String groupChatId,
    required String query,
  }) async {
    try {
      // Note: PocketBase supports limited text search
      // This implementation gets messages and filters client-side
      // For production, consider using full-text search or external search service
      final records = await _pb.collection(AppConstants.messagesCollection).getList(
        page: 1,
        perPage: 500,
        sort: '-timestamp',
        filter: 'groupChatId = "$groupChatId"',
      );

      final allMessages = records.items
          .map((record) => MessageModel.fromPocketBase(record))
          .toList();

      // Filter messages containing the query (case-insensitive)
      return allMessages
          .where((message) =>
              message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } on ClientException catch (e) {
      throw 'Failed to search messages: ${e.response}';
    } catch (e) {
      throw 'Failed to search messages: $e';
    }
  }

  // Add reaction to a message
  Future<void> addReaction({
    required String groupChatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      // Get the current message
      final messageRecord = await _pb.collection(AppConstants.messagesCollection).getOne(messageId);

      if (messageRecord.id.isEmpty) {
        throw 'Message not found';
      }

      // Get current reactions
      Map<String, dynamic> reactions = Map<String, dynamic>.from(
        messageRecord.data['reactions'] ?? {},
      );

      // Add user to the emoji's list
      if (reactions.containsKey(emoji)) {
        List<String> users = List<String>.from(reactions[emoji]);
        if (!users.contains(userId)) {
          users.add(userId);
          reactions[emoji] = users;
        }
      } else {
        reactions[emoji] = [userId];
      }

      // Update message with new reactions
      await _pb.collection(AppConstants.messagesCollection).update(
        messageId,
        body: {'reactions': reactions},
      );
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw 'Message not found';
      }
      throw 'Failed to add reaction: ${e.response}';
    } catch (e) {
      throw 'Failed to add reaction: $e';
    }
  }

  // Remove reaction from a message
  Future<void> removeReaction({
    required String groupChatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      // Get the current message
      final messageRecord = await _pb.collection(AppConstants.messagesCollection).getOne(messageId);

      if (messageRecord.id.isEmpty) {
        throw 'Message not found';
      }

      // Get current reactions
      Map<String, dynamic> reactions = Map<String, dynamic>.from(
        messageRecord.data['reactions'] ?? {},
      );

      // Remove user from the emoji's list
      if (reactions.containsKey(emoji)) {
        List<String> users = List<String>.from(reactions[emoji]);
        users.remove(userId);

        if (users.isEmpty) {
          // Remove emoji if no users left
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }
      }

      // Update message with new reactions
      await _pb.collection(AppConstants.messagesCollection).update(
        messageId,
        body: {'reactions': reactions},
      );
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw 'Message not found';
      }
      throw 'Failed to remove reaction: ${e.response}';
    } catch (e) {
      throw 'Failed to remove reaction: $e';
    }
  }

  // Cleanup method to dispose of stream controllers
  void dispose() {
    for (var controller in _messageStreams.values) {
      controller.close();
    }
    _messageStreams.clear();

    for (var controller in _typingStreams.values) {
      controller.close();
    }
    _typingStreams.clear();

    // Unsubscribe from all PocketBase subscriptions
    _pb.collection(AppConstants.messagesCollection).unsubscribe('*');
    _pb.collection('typing').unsubscribe('*');
  }
}
