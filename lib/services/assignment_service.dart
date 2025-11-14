import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create assignment
  Future<String> createAssignment({
    required String communityId,
    required String groupChatId,
    required String title,
    required String description,
    required String createdBy,
    required String creatorName,
    required DateTime dueDate,
    required int totalPoints,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      final docRef = await _firestore.collection('assignments').add({
        'communityId': communityId,
        'groupChatId': groupChatId,
        'title': title,
        'description': description,
        'createdBy': createdBy,
        'creatorName': creatorName,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': Timestamp.fromDate(dueDate),
        'totalPoints': totalPoints,
        'attachmentUrls': attachmentUrls,
        'submittedBy': [],
        'submissions': {},
        'isActive': true,
      });

      return docRef.id;
    } catch (e) {
      throw 'Failed to create assignment: $e';
    }
  }

  // Get assignments for a group
  Stream<List<AssignmentModel>> getAssignments(String groupChatId) {
    return _firestore
        .collection('assignments')
        .where('groupChatId', isEqualTo: groupChatId)
        .where('isActive', isEqualTo: true)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromFirestore(doc))
            .toList());
  }

  // Submit assignment
  Future<void> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required List<String> fileUrls,
    String? notes,
  }) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).update({
        'submittedBy': FieldValue.arrayUnion([studentId]),
        'submissions.$studentId': {
          'studentId': studentId,
          'studentName': studentName,
          'submittedAt': FieldValue.serverTimestamp(),
          'fileUrls': fileUrls,
          'notes': notes,
          'grade': null,
          'feedback': null,
          'gradedAt': null,
        },
      });
    } catch (e) {
      throw 'Failed to submit assignment: $e';
    }
  }

  // Grade submission
  Future<void> gradeSubmission({
    required String assignmentId,
    required String studentId,
    required int grade,
    String? feedback,
  }) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).update({
        'submissions.$studentId.grade': grade,
        'submissions.$studentId.feedback': feedback,
        'submissions.$studentId.gradedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to grade submission: $e';
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({'isActive': false});
    } catch (e) {
      throw 'Failed to delete assignment: $e';
    }
  }
}
