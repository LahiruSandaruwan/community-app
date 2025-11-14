import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/group_chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<MessageModel> _messages = [];
  GroupChatModel? _selectedGroupChat;
  List<String> _typingUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MessageModel> get messages => _messages;
  GroupChatModel? get selectedGroupChat => _selectedGroupChat;
  List<String> get typingUsers => _typingUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Select group chat
  void selectGroupChat(GroupChatModel groupChat, String currentUserId) {
    _selectedGroupChat = groupChat;
    loadMessages(groupChat.id);
    listenToTypingUsers(groupChat.id, currentUserId);
    notifyListeners();
  }

  // Load messages
  void loadMessages(String groupChatId) {
    _chatService.getMessages(groupChatId: groupChatId).listen((messages) {
      _messages = messages;
      notifyListeners();
    });
  }

  // Send message
  Future<bool> sendMessage({
    required String groupChatId,
    required String senderId,
    required String senderName,
    String? senderProfileUrl,
    required String content,
    String messageType = 'text',
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    if (content.trim().isEmpty) return false;

    _errorMessage = null;

    try {
      await _chatService.sendMessage(
        groupChatId: groupChatId,
        senderId: senderId,
        senderName: senderName,
        senderProfileUrl: senderProfileUrl,
        content: content,
        messageType: messageType,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead({
    required String groupChatId,
    required String messageId,
    required String userId,
  }) async {
    await _chatService.markMessageAsRead(
      groupChatId: groupChatId,
      messageId: messageId,
      userId: userId,
    );
  }

  // Mark all messages as read
  Future<void> markAllMessagesAsRead({
    required String groupChatId,
    required String userId,
  }) async {
    await _chatService.markAllMessagesAsRead(
      groupChatId: groupChatId,
      userId: userId,
    );
  }

  // Toggle pin message
  Future<bool> togglePinMessage({
    required String groupChatId,
    required String messageId,
    required bool pin,
  }) async {
    _errorMessage = null;

    try {
      await _chatService.togglePinMessage(
        groupChatId: groupChatId,
        messageId: messageId,
        pin: pin,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete message
  Future<bool> deleteMessage({
    required String groupChatId,
    required String messageId,
  }) async {
    _errorMessage = null;

    try {
      await _chatService.deleteMessage(
        groupChatId: groupChatId,
        messageId: messageId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Set typing indicator
  Future<void> setTypingIndicator({
    required String groupChatId,
    required String userId,
    required bool isTyping,
  }) async {
    await _chatService.setTypingIndicator(
      groupChatId: groupChatId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  // Listen to typing users
  void listenToTypingUsers(String groupChatId, String currentUserId) {
    _chatService
        .getTypingUsers(
      groupChatId: groupChatId,
      currentUserId: currentUserId,
    )
        .listen((typingUserIds) {
      _typingUsers = typingUserIds;
      notifyListeners();
    });
  }

  // Get unread count
  Future<int> getUnreadCount({
    required String groupChatId,
    required String userId,
  }) async {
    return await _chatService.getUnreadCount(
      groupChatId: groupChatId,
      userId: userId,
    );
  }

  // Search messages
  Future<List<MessageModel>> searchMessages({
    required String groupChatId,
    required String query,
  }) async {
    try {
      return await _chatService.searchMessages(
        groupChatId: groupChatId,
        query: query,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Add reaction to message
  Future<bool> addReaction({
    required String groupChatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    _errorMessage = null;

    try {
      await _chatService.addReaction(
        groupChatId: groupChatId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove reaction from message
  Future<bool> removeReaction({
    required String groupChatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    _errorMessage = null;

    try {
      await _chatService.removeReaction(
        groupChatId: groupChatId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear selected group chat
  void clearSelectedGroupChat() {
    _selectedGroupChat = null;
    _messages = [];
    _typingUsers = [];
    notifyListeners();
  }
}
