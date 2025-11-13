import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      profilePictureUrl: data['profilePictureUrl'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      fcmToken: data['fcmToken'],
      communityIds: List<String>.from(data['communityIds'] ?? []),
    );
  }

  // Convert UserModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'profilePictureUrl': profilePictureUrl,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'communityIds': communityIds,
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
    );
  }

  bool get isTutor => role == 'tutor';
  bool get isStudent => role == 'student';
}
