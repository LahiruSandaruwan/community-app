import 'package:pocketbase/pocketbase.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String createdBy; // Tutor user ID
  final DateTime createdAt;
  final String? communityImageUrl;
  final List<String> memberIds; // All members (tutor + students)
  final List<String> adminIds; // Tutors who can manage the community
  final List<String> groupChatIds; // Group chats within this community
  final String inviteCode; // Unique code for joining
  final bool isActive;
  final Map<String, dynamic>? metadata; // For future extensions

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.communityImageUrl,
    this.memberIds = const [],
    this.adminIds = const [],
    this.groupChatIds = const [],
    required this.inviteCode,
    this.isActive = true,
    this.metadata,
  });

  // Create CommunityModel from PocketBase record
  factory CommunityModel.fromPocketBase(RecordModel record) {
    return CommunityModel(
      id: record.id,
      name: record.getStringValue('name'),
      description: record.getStringValue('description'),
      createdBy: record.getStringValue('createdBy'),
      createdAt: DateTime.parse(record.getStringValue('createdAt', DateTime.now().toIso8601String())),
      communityImageUrl: record.getStringValue('communityImageUrl', '').isEmpty
          ? null
          : record.getStringValue('communityImageUrl'),
      memberIds: record.getListValue<String>('memberIds'),
      adminIds: record.getListValue<String>('adminIds'),
      groupChatIds: record.getListValue<String>('groupChatIds'),
      inviteCode: record.getStringValue('inviteCode'),
      isActive: record.getBoolValue('isActive', true),
      metadata: record.data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert CommunityModel to PocketBase record data
  Map<String, dynamic> toPocketBase() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'communityImageUrl': communityImageUrl ?? '',
      'memberIds': memberIds,
      'adminIds': adminIds,
      'groupChatIds': groupChatIds,
      'inviteCode': inviteCode,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    String? communityImageUrl,
    List<String>? memberIds,
    List<String>? adminIds,
    List<String>? groupChatIds,
    String? inviteCode,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      communityImageUrl: communityImageUrl ?? this.communityImageUrl,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      groupChatIds: groupChatIds ?? this.groupChatIds,
      inviteCode: inviteCode ?? this.inviteCode,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  int get memberCount => memberIds.length;
  int get groupCount => groupChatIds.length;
}
