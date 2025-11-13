import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Create CommunityModel from Firestore document
  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      communityImageUrl: data['communityImageUrl'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      groupChatIds: List<String>.from(data['groupChatIds'] ?? []),
      inviteCode: data['inviteCode'] ?? '',
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  // Convert CommunityModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'communityImageUrl': communityImageUrl,
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
