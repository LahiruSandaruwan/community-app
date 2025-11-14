import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatsModel {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalPoints;
  final int level;
  final List<String> badges;
  final Map<String, int> activityCounts; // message, assignment, etc.

  UserStatsModel({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalPoints = 0,
    this.level = 1,
    this.badges = const [],
    this.activityCounts = const {},
  });

  factory UserStatsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserStatsModel(
      userId: doc.id,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'] != null
          ? (data['lastActiveDate'] as Timestamp).toDate()
          : null,
      totalPoints: data['totalPoints'] ?? 0,
      level: data['level'] ?? 1,
      badges: List<String>.from(data['badges'] ?? []),
      activityCounts: Map<String, int>.from(data['activityCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'totalPoints': totalPoints,
      'level': level,
      'badges': badges,
      'activityCounts': activityCounts,
    };
  }

  int get pointsToNextLevel => (level * 100);
  double get progressToNextLevel => (totalPoints % pointsToNextLevel) / pointsToNextLevel;
}

class AttendanceModel {
  final String id;
  final String groupChatId;
  final String sessionName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> presentUserIds;
  final List<String> lateUserIds;
  final String createdBy;

  AttendanceModel({
    required this.id,
    required this.groupChatId,
    required this.sessionName,
    required this.startTime,
    this.endTime,
    this.presentUserIds = const [],
    this.lateUserIds = const [],
    required this.createdBy,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AttendanceModel(
      id: doc.id,
      groupChatId: data['groupChatId'] ?? '',
      sessionName: data['sessionName'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      presentUserIds: List<String>.from(data['presentUserIds'] ?? []),
      lateUserIds: List<String>.from(data['lateUserIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupChatId': groupChatId,
      'sessionName': sessionName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'presentUserIds': presentUserIds,
      'lateUserIds': lateUserIds,
      'createdBy': createdBy,
    };
  }
}
