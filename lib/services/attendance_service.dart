import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get sessions stream for a group chat
  Stream<List<AttendanceModel>> getSessions(String groupChatId) {
    return _firestore
        .collection('attendance')
        .where('groupChatId', isEqualTo: groupChatId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Create a new attendance session
  Future<String> createSession({
    required String groupChatId,
    required String sessionName,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection('attendance').add({
        'groupChatId': groupChatId,
        'sessionName': sessionName,
        'createdBy': createdBy,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'presentUserIds': [],
        'lateUserIds': [],
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Mark attendance for a user
  Future<void> markAttendance({
    required String sessionId,
    required String userId,
    bool isLate = false,
  }) async {
    try {
      final docRef = _firestore.collection('attendance').doc(sessionId);

      if (isLate) {
        await docRef.update({
          'lateUserIds': FieldValue.arrayUnion([userId]),
        });
      } else {
        await docRef.update({
          'presentUserIds': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // End an attendance session
  Future<void> endSession(String sessionId) async {
    try {
      await _firestore.collection('attendance').doc(sessionId).update({
        'endTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  // Get a single session
  Future<AttendanceModel?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('attendance').doc(sessionId).get();

      if (!doc.exists) return null;

      return AttendanceModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Delete a session (optional - for cleanup)
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('attendance').doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // Get attendance stats for a user in a group
  Future<Map<String, int>> getUserAttendanceStats({
    required String groupChatId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('groupChatId', isEqualTo: groupChatId)
          .get();

      int present = 0;
      int late = 0;
      int absent = 0;

      for (var doc in snapshot.docs) {
        final session = AttendanceModel.fromMap(doc.data(), doc.id);

        if (session.presentUserIds.contains(userId)) {
          present++;
        } else if (session.lateUserIds.contains(userId)) {
          late++;
        } else {
          absent++;
        }
      }

      return {
        'present': present,
        'late': late,
        'absent': absent,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get attendance stats: $e');
    }
  }
}
