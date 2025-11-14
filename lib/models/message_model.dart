import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse reactions
    Map<String, List<String>> reactions = {};
    if (data['reactions'] != null) {
      final reactionsData = data['reactions'] as Map<String, dynamic>;
      reactionsData.forEach((emoji, userIds) {
        reactions[emoji] = List<String>.from(userIds ?? []);
      });
    }

    return MessageModel(
      id: doc.id,
      groupChatId: data['groupChatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfileUrl: data['senderProfileUrl'],
      content: data['content'] ?? '',
      messageType: data['messageType'] ?? 'text',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
      isPinned: data['isPinned'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      metadata: data['metadata'],
      reactions: reactions,
    );
  }

  // Convert MessageModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'groupChatId': groupChatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileUrl': senderProfileUrl,
      'content': content,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'isPinned': isPinned,
      'replyToMessageId': replyToMessageId,
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
