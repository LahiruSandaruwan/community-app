import 'package:pocketbase/pocketbase.dart';

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

  // Create GroupChatModel from PocketBase record
  factory GroupChatModel.fromPocketBase(RecordModel record) {
    final lastMessageAtStr = record.getStringValue('lastMessageAt', '');
    return GroupChatModel(
      id: record.id,
      name: record.getStringValue('name'),
      description: record.getStringValue('description'),
      communityId: record.getStringValue('communityId'),
      createdBy: record.getStringValue('createdBy'),
      createdAt: DateTime.parse(record.getStringValue('createdAt', DateTime.now().toIso8601String())),
      groupImageUrl: record.getStringValue('groupImageUrl', '').isEmpty
          ? null
          : record.getStringValue('groupImageUrl'),
      memberIds: record.getListValue<String>('memberIds'),
      isAnnouncementOnly: record.getBoolValue('isAnnouncementOnly'),
      lastMessageAt: lastMessageAtStr.isEmpty ? null : DateTime.parse(lastMessageAtStr),
      lastMessage: record.getStringValue('lastMessage', '').isEmpty
          ? null
          : record.getStringValue('lastMessage'),
      lastMessageSenderId: record.getStringValue('lastMessageSenderId', '').isEmpty
          ? null
          : record.getStringValue('lastMessageSenderId'),
      unreadCounts: Map<String, int>.from(record.data['unreadCounts'] ?? {}),
      pinnedMessageIds: record.getListValue<String>('pinnedMessageIds'),
      isActive: record.getBoolValue('isActive', true),
    );
  }

  // Convert GroupChatModel to PocketBase record data
  Map<String, dynamic> toPocketBase() {
    return {
      'name': name,
      'description': description,
      'communityId': communityId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'groupImageUrl': groupImageUrl ?? '',
      'memberIds': memberIds,
      'isAnnouncementOnly': isAnnouncementOnly,
      'lastMessageAt': lastMessageAt?.toIso8601String() ?? '',
      'lastMessage': lastMessage ?? '',
      'lastMessageSenderId': lastMessageSenderId ?? '',
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
