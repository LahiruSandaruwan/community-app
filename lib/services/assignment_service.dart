import 'package:pocketbase/pocketbase.dart';
import '../models/assignment_model.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class AssignmentService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<List<AssignmentModel>>> _assignmentStreams = {};
  final Map<String, Timer> _pollingTimers = {};

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
      final now = DateTime.now();

      final assignmentData = {
        'communityId': communityId,
        'groupChatId': groupChatId,
        'title': title,
        'description': description,
        'createdBy': createdBy,
        'creatorName': creatorName,
        'createdAt': now.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'totalPoints': totalPoints,
        'attachmentUrls': attachmentUrls,
        'submittedBy': [],
        'submissions': {},
        'isActive': true,
      };

      final record = await _pb.collection('assignments').create(body: assignmentData);

      return record.id;
    } on ClientException catch (e) {
      throw 'Failed to create assignment: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to create assignment: $e';
    }
  }

  // Get assignments for a group
  Stream<List<AssignmentModel>> getAssignments(String groupChatId) {
    final streamKey = 'assignments_$groupChatId';

    // Return existing stream if already active
    if (_assignmentStreams.containsKey(streamKey)) {
      return _assignmentStreams[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<List<AssignmentModel>>.broadcast(
      onCancel: () {
        _pollingTimers[streamKey]?.cancel();
        _pollingTimers.remove(streamKey);
        _assignmentStreams.remove(streamKey);
      },
    );

    _assignmentStreams[streamKey] = controller;

    // Fetch and emit data periodically
    void fetchData() async {
      try {
        final records = await _pb.collection('assignments').getFullList(
          filter: 'groupChatId = "$groupChatId" && isActive = true',
          sort: '+dueDate',
        );

        if (!controller.isClosed) {
          controller.add(
            records.map((record) => AssignmentModel.fromPocketBase(record)).toList()
          );
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError('Failed to fetch assignments: $e');
        }
      }
    }

    // Initial fetch
    fetchData();

    // Poll every 3 seconds
    _pollingTimers[streamKey] = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchData(),
    );

    return controller.stream;
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
      // Get current assignment
      final assignment = await _pb.collection('assignments').getOne(assignmentId);

      // Update submittedBy array
      final submittedBy = List<String>.from(assignment.data['submittedBy'] ?? []);
      if (!submittedBy.contains(studentId)) {
        submittedBy.add(studentId);
      }

      // Update submissions map
      final submissions = Map<String, dynamic>.from(assignment.data['submissions'] ?? {});
      submissions[studentId] = {
        'studentId': studentId,
        'studentName': studentName,
        'submittedAt': DateTime.now().toIso8601String(),
        'fileUrls': fileUrls,
        'notes': notes,
        'grade': null,
        'feedback': null,
        'gradedAt': null,
      };

      await _pb.collection('assignments').update(
        assignmentId,
        body: {
          'submittedBy': submittedBy,
          'submissions': submissions,
        },
      );
    } on ClientException catch (e) {
      throw 'Failed to submit assignment: ${e.response['message'] ?? e.toString()}';
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
      // Get current assignment
      final assignment = await _pb.collection('assignments').getOne(assignmentId);

      // Update submissions map
      final submissions = Map<String, dynamic>.from(assignment.data['submissions'] ?? {});

      if (submissions.containsKey(studentId)) {
        final submission = Map<String, dynamic>.from(submissions[studentId]);
        submission['grade'] = grade;
        submission['feedback'] = feedback;
        submission['gradedAt'] = DateTime.now().toIso8601String();
        submissions[studentId] = submission;

        await _pb.collection('assignments').update(
          assignmentId,
          body: {'submissions': submissions},
        );
      } else {
        throw 'Submission not found for student';
      }
    } on ClientException catch (e) {
      throw 'Failed to grade submission: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to grade submission: $e';
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _pb.collection('assignments').update(
        assignmentId,
        body: {'isActive': false},
      );
    } on ClientException catch (e) {
      throw 'Failed to delete assignment: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to delete assignment: $e';
    }
  }

  // Cleanup resources
  void dispose() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    for (var controller in _assignmentStreams.values) {
      controller.close();
    }
    _pollingTimers.clear();
    _assignmentStreams.clear();
  }
}
