import 'package:flutter/material.dart';
import '../services/bookmark_service.dart';

class BookmarkProvider with ChangeNotifier {
  final BookmarkService _bookmarkService = BookmarkService();

  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load bookmarks for a user
  void loadBookmarks(String userId) {
    _bookmarkService.getBookmarks(userId: userId).listen((bookmarks) {
      _bookmarks = bookmarks;
      notifyListeners();
    });
  }

  // Add bookmark
  Future<bool> addBookmark({
    required String userId,
    required String groupChatId,
    required String messageId,
    String? note,
  }) async {
    _errorMessage = null;

    try {
      await _bookmarkService.addBookmark(
        userId: userId,
        groupChatId: groupChatId,
        messageId: messageId,
        note: note,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove bookmark
  Future<bool> removeBookmark({
    required String userId,
    required String messageId,
  }) async {
    _errorMessage = null;

    try {
      await _bookmarkService.removeBookmark(
        userId: userId,
        messageId: messageId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if message is bookmarked
  Future<bool> isBookmarked({
    required String userId,
    required String messageId,
  }) async {
    return await _bookmarkService.isBookmarked(
      userId: userId,
      messageId: messageId,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
