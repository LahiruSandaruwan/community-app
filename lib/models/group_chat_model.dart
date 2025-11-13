import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatModel {
  final String id;
  final String name;
  final String description;
  final String communityId; // Parent community
  final String createdBy; // Admin/Tutor who created
  final DateTime createdAt;
  final String? groupImageUrl;
  final List<String> memberIds; // Members who can participate
  final bool isAnnouncementOnly; // Only admins can post
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts; // userId -> unread count
  final List<String> pinnedMessageIds; // Pinned messages
  final bool isActive;

  GroupChatModel({
    required this.id,
    required this.name,
    required this.description,
    required this.communityId,
    required this.createdBy,
    required this.createdAt,
    this.groupImageUrl,
    this.memberIds = const [],
    this.isAnnouncementOnly = false,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.unreadCounts = const {},
    this.pinnedMessageIds = const [],
    this.isActive = true,
  });

  // Create GroupChatModel from Firestore document
  factory GroupChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupChatModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      communityId: data['communityId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      groupImageUrl: data['groupImageUrl'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      isAnnouncementOnly: data['isAnnouncementOnly'] ?? false,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      pinnedMessageIds: List<String>.from(data['pinnedMessageIds'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert GroupChatModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'communityId': communityId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupImageUrl': groupImageUrl,
      'memberIds': memberIds,
      'isAnnouncementOnly': isAnnouncementOnly,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
      'pinnedMessageIds': pinnedMessageIds,
      'isActive': isActive,
    };
  }

  // Create a copy with updated fields
  GroupChatModel copyWith({
    String? id,
    String? name,
    String? description,
    String? communityId,
    String? createdBy,
    DateTime? createdAt,
    String? groupImageUrl,
    List<String>? memberIds,
    bool? isAnnouncementOnly,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    List<String>? pinnedMessageIds,
    bool? isActive,
  }) {
    return GroupChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      communityId: communityId ?? this.communityId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      memberIds: memberIds ?? this.memberIds,
      isAnnouncementOnly: isAnnouncementOnly ?? this.isAnnouncementOnly,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      pinnedMessageIds: pinnedMessageIds ?? this.pinnedMessageIds,
      isActive: isActive ?? this.isActive,
    );
  }

  int get memberCount => memberIds.length;
  int get pinnedCount => pinnedMessageIds.length;
}
