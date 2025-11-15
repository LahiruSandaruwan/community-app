import 'package:pocketbase/pocketbase.dart';

class MessageModel {
  final String id;
  final String groupChatId;
  final String senderId;
  final String senderName;
  final String? senderProfileUrl;
  final String content;
  final String messageType; // 'text', 'image', 'announcement'
  final DateTime timestamp;
  final List<String> readBy; // User IDs who have read the message
  final bool isPinned;
  final String? replyToMessageId; // For message replies
  final Map<String, dynamic>? metadata; // For future extensions
  final Map<String, List<String>> reactions; // emoji -> list of user IDs

  MessageModel({
    required this.id,
    required this.groupChatId,
    required this.senderId,
    required this.senderName,
    this.senderProfileUrl,
    required this.content,
    this.messageType = 'text',
    required this.timestamp,
    this.readBy = const [],
    this.isPinned = false,
    this.replyToMessageId,
    this.metadata,
    this.reactions = const {},
  });

  // Create MessageModel from PocketBase record
  factory MessageModel.fromPocketBase(RecordModel record) {
    // Parse reactions
    Map<String, List<String>> reactions = {};
    if (record.data['reactions'] != null) {
      final reactionsData = record.data['reactions'] as Map<String, dynamic>;
      reactionsData.forEach((emoji, userIds) {
        reactions[emoji] = List<String>.from(userIds ?? []);
      });
    }

    return MessageModel(
      id: record.id,
      groupChatId: record.getStringValue('groupChatId'),
      senderId: record.getStringValue('senderId'),
      senderName: record.getStringValue('senderName'),
      senderProfileUrl: record.getStringValue('senderProfileUrl', '').isEmpty
          ? null
          : record.getStringValue('senderProfileUrl'),
      content: record.getStringValue('content'),
      messageType: record.getStringValue('messageType', 'text'),
      timestamp: DateTime.parse(record.getStringValue('timestamp', DateTime.now().toIso8601String())),
      readBy: record.getListValue<String>('readBy'),
      isPinned: record.getBoolValue('isPinned'),
      replyToMessageId: record.getStringValue('replyToMessageId', '').isEmpty
          ? null
          : record.getStringValue('replyToMessageId'),
      metadata: record.data['metadata'] as Map<String, dynamic>?,
      reactions: reactions,
    );
  }

  // Convert MessageModel to PocketBase record data
  Map<String, dynamic> toPocketBase() {
    return {
      'groupChatId': groupChatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileUrl': senderProfileUrl ?? '',
      'content': content,
      'messageType': messageType,
      'timestamp': timestamp.toIso8601String(),
      'readBy': readBy,
      'isPinned': isPinned,
      'replyToMessageId': replyToMessageId ?? '',
      'metadata': metadata,
      'reactions': reactions,
    };
  }

  // Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? groupChatId,
    String? senderId,
    String? senderName,
    String? senderProfileUrl,
    String? content,
    String? messageType,
    DateTime? timestamp,
    List<String>? readBy,
    bool? isPinned,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    Map<String, List<String>>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      groupChatId: groupChatId ?? this.groupChatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileUrl: senderProfileUrl ?? this.senderProfileUrl,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      isPinned: isPinned ?? this.isPinned,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
    );
  }

  bool isReadBy(String userId) => readBy.contains(userId);
  int get readCount => readBy.length;
  bool get isAnnouncement => messageType == 'announcement';
}
