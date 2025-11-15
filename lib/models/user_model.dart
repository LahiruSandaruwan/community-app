import 'package:pocketbase/pocketbase.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'tutor' or 'student'
  final String? profilePictureUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final String? fcmToken;
  final List<String> communityIds; // Communities user is part of
  final List<String> mutedGroupChatIds; // Group chats with muted notifications

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profilePictureUrl,
    this.phoneNumber,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.fcmToken,
    this.communityIds = const [],
    this.mutedGroupChatIds = const [],
  });

  // Create UserModel from PocketBase record
  factory UserModel.fromPocketBase(RecordModel record) {
    return UserModel(
      id: record.id,
      email: record.getStringValue('email'),
      name: record.getStringValue('name'),
      role: record.getStringValue('role', 'student'),
      profilePictureUrl: record.getStringValue('profilePictureUrl', '').isEmpty
          ? null
          : record.getStringValue('profilePictureUrl'),
      phoneNumber: record.getStringValue('phoneNumber', '').isEmpty
          ? null
          : record.getStringValue('phoneNumber'),
      createdAt: DateTime.parse(record.getStringValue('createdAt', DateTime.now().toIso8601String())),
      lastSeen: DateTime.parse(record.getStringValue('lastSeen', DateTime.now().toIso8601String())),
      isOnline: record.getBoolValue('isOnline'),
      fcmToken: record.getStringValue('fcmToken', '').isEmpty
          ? null
          : record.getStringValue('fcmToken'),
      communityIds: record.getListValue<String>('communityIds'),
      mutedGroupChatIds: record.getListValue<String>('mutedGroupChatIds'),
    );
  }

  // Convert UserModel to PocketBase record data
  Map<String, dynamic> toPocketBase() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'profilePictureUrl': profilePictureUrl ?? '',
      'phoneNumber': phoneNumber ?? '',
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'isOnline': isOnline,
      'fcmToken': fcmToken ?? '',
      'communityIds': communityIds,
      'mutedGroupChatIds': mutedGroupChatIds,
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? profilePictureUrl,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    String? fcmToken,
    List<String>? communityIds,
    List<String>? mutedGroupChatIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      fcmToken: fcmToken ?? this.fcmToken,
      communityIds: communityIds ?? this.communityIds,
      mutedGroupChatIds: mutedGroupChatIds ?? this.mutedGroupChatIds,
    );
  }

  bool get isTutor => role == 'tutor';
  bool get isStudent => role == 'student';
}
