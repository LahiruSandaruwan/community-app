import 'package:flutter/material.dart';
import '../models/user_stats_model.dart';
import '../services/gamification_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceModel> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load sessions
  void loadSessions(String groupChatId) {
    _attendanceService.getSessions(groupChatId).listen((sessions) {
      _sessions = sessions;
      notifyListeners();
    });
  }

  // Create session
  Future<String?> createSession({
    required String groupChatId,
    required String sessionName,
    required String createdBy,
  }) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final sessionId = await _attendanceService.createSession(
        groupChatId: groupChatId,
        sessionName: sessionName,
        createdBy: createdBy,
      );
      _isLoading = false;
      notifyListeners();
      return sessionId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Mark attendance
  Future<bool> markAttendance({
    required String sessionId,
    required String userId,
    bool isLate = false,
  }) async {
    _errorMessage = null;

    try {
      await _attendanceService.markAttendance(
        sessionId: sessionId,
        userId: userId,
        isLate: isLate,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // End session
  Future<bool> endSession(String sessionId) async {
    _errorMessage = null;

    try {
      await _attendanceService.endSession(sessionId);
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
