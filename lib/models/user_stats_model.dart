import 'package:pocketbase/pocketbase.dart';

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

  factory UserStatsModel.fromPocketBase(RecordModel record) {
    // Parse activityCounts from JSON
    Map<String, int> activityCounts = {};
    final activityData = record.data['activityCounts'];
    if (activityData != null && activityData is Map) {
      activityData.forEach((key, value) {
        if (value is int) {
          activityCounts[key.toString()] = value;
        }
      });
    }

    return UserStatsModel(
      userId: record.id,
      currentStreak: record.getIntValue('currentStreak'),
      longestStreak: record.getIntValue('longestStreak'),
      lastActiveDate: record.getStringValue('lastActiveDate', '').isEmpty
          ? null
          : DateTime.parse(record.getStringValue('lastActiveDate')),
      totalPoints: record.getIntValue('totalPoints'),
      level: record.getIntValue('level', 1),
      badges: record.getListValue<String>('badges'),
      activityCounts: activityCounts,
    );
  }

  Map<String, dynamic> toPocketBase() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String() ?? '',
      'totalPoints': totalPoints,
      'level': level,
      'badges': badges,
      'activityCounts': activityCounts,
    };
  }

  int get pointsToNextLevel => (level * 100);
  double get progressToNextLevel => (totalPoints % pointsToNextLevel) / pointsToNextLevel;
}
