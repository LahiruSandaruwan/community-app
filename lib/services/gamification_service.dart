import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_stats_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update user activity and award points
  Future<void> recordActivity({
    required String userId,
    required String activityType,
    int points = 10,
  }) async {
    try {
      final userStatsRef = _firestore.collection('userStats').doc(userId);
      final doc = await userStatsRef.get();

      if (!doc.exists) {
        // Create new stats
        await userStatsRef.set({
          'currentStreak': 1,
          'longestStreak': 1,
          'lastActiveDate': FieldValue.serverTimestamp(),
          'totalPoints': points,
          'level': 1,
          'badges': [],
          'activityCounts': {activityType: 1},
        });
      } else {
        // Update existing stats
        final data = doc.data()!;
        final lastActive = data['lastActiveDate'] != null
            ? (data['lastActiveDate'] as Timestamp).toDate()
            : null;
        final now = DateTime.now();

        int currentStreak = data['currentStreak'] ?? 0;
        int longestStreak = data['longestStreak'] ?? 0;

        // Check streak
        if (lastActive != null) {
          final daysDiff = now.difference(lastActive).inDays;
          if (daysDiff == 1) {
            currentStreak++;
          } else if (daysDiff > 1) {
            currentStreak = 1;
          }
          longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
        }

        final totalPoints = (data['totalPoints'] ?? 0) + points;
        final level = (totalPoints ~/ 100) + 1;

        Map<String, dynamic> activityCounts =
            Map<String, dynamic>.from(data['activityCounts'] ?? {});
        activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1;

        await userStatsRef.update({
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastActiveDate': FieldValue.serverTimestamp(),
          'totalPoints': totalPoints,
          'level': level,
          'activityCounts': activityCounts,
        });
      }
    } catch (e) {
      print('Failed to record activity: $e');
    }
  }

  // Get user stats
  Stream<UserStatsModel?> getUserStats(String userId) {
    return _firestore
        .collection('userStats')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserStatsModel.fromFirestore(doc) : null);
  }

  // Get leaderboard
  Future<List<UserStatsModel>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('userStats')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserStatsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create attendance session
  Future<String> createSession({
    required String groupChatId,
    required String sessionName,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection('attendance').add({
        'groupChatId': groupChatId,
        'sessionName': sessionName,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'presentUserIds': [],
        'lateUserIds': [],
        'createdBy': createdBy,
      });

      return docRef.id;
    } catch (e) {
      throw 'Failed to create session: $e';
    }
  }

  // Mark attendance
  Future<void> markAttendance({
    required String sessionId,
    required String userId,
    bool isLate = false,
  }) async {
    try {
      final field = isLate ? 'lateUserIds' : 'presentUserIds';
      await _firestore.collection('attendance').doc(sessionId).update({
        field: FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw 'Failed to mark attendance: $e';
    }
  }

  // End session
  Future<void> endSession(String sessionId) async {
    try {
      await _firestore.collection('attendance').doc(sessionId).update({
        'endTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to end session: $e';
    }
  }

  // Get sessions
  Stream<List<AttendanceModel>> getSessions(String groupChatId) {
    return _firestore
        .collection('attendance')
        .where('groupChatId', isEqualTo: groupChatId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList());
  }
}
