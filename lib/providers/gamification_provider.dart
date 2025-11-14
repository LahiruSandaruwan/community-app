import 'package:flutter/material.dart';
import '../models/user_stats_model.dart';
import '../services/gamification_service.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _gamificationService = GamificationService();

  UserStatsModel? _userStats;
  List<UserStatsModel> _leaderboard = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserStatsModel? get userStats => _userStats;
  List<UserStatsModel> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load user stats
  void loadUserStats(String userId) {
    _gamificationService.getUserStats(userId).listen((stats) {
      _userStats = stats;
      notifyListeners();
    });
  }

  // Load leaderboard
  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      _leaderboard = await _gamificationService.getLeaderboard(limit: 10);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record activity (called automatically)
  Future<void> recordActivity({
    required String userId,
    required String activityType,
    int points = 10,
  }) async {
    await _gamificationService.recordActivity(
      userId: userId,
      activityType: activityType,
      points: points,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
