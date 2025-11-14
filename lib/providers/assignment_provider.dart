import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();

  List<AssignmentModel> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AssignmentModel> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load assignments for a group
  void loadAssignments(String groupChatId) {
    _assignmentService.getAssignments(groupChatId).listen((assignments) {
      _assignments = assignments;
      notifyListeners();
    });
  }

  // Create assignment
  Future<bool> createAssignment({
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
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _assignmentService.createAssignment(
        communityId: communityId,
        groupChatId: groupChatId,
        title: title,
        description: description,
        createdBy: createdBy,
        creatorName: creatorName,
        dueDate: dueDate,
        totalPoints: totalPoints,
        attachmentUrls: attachmentUrls,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Submit assignment
  Future<bool> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required List<String> fileUrls,
    String? notes,
  }) async {
    _errorMessage = null;

    try {
      await _assignmentService.submitAssignment(
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: studentName,
        fileUrls: fileUrls,
        notes: notes,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Grade submission
  Future<bool> gradeSubmission({
    required String assignmentId,
    required String studentId,
    required int grade,
    String? feedback,
  }) async {
    _errorMessage = null;

    try {
      await _assignmentService.gradeSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        grade: grade,
        feedback: feedback,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
