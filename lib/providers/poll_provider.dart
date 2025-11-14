import 'package:flutter/material.dart';
import '../models/poll_model.dart';
import '../services/poll_service.dart';

class PollProvider with ChangeNotifier {
  final PollService _pollService = PollService();

  PollModel? _currentPoll;
  bool _isLoading = false;
  String? _errorMessage;

  PollModel? get currentPoll => _currentPoll;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create poll
  Future<String?> createPoll({
    required String groupChatId,
    required String question,
    required List<String> options,
    required String createdBy,
    DateTime? expiresAt,
    bool allowMultiple = false,
    bool isAnonymous = false,
  }) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final pollId = await _pollService.createPoll(
        groupChatId: groupChatId,
        question: question,
        options: options,
        createdBy: createdBy,
        expiresAt: expiresAt,
        allowMultiple: allowMultiple,
        isAnonymous: isAnonymous,
      );
      _isLoading = false;
      notifyListeners();
      return pollId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Vote on poll
  Future<bool> vote({
    required String pollId,
    required String userId,
    required String option,
  }) async {
    _errorMessage = null;

    try {
      await _pollService.vote(
        pollId: pollId,
        userId: userId,
        option: option,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load poll
  void loadPoll(String pollId) {
    _pollService.getPoll(pollId).listen((poll) {
      _currentPoll = poll;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
