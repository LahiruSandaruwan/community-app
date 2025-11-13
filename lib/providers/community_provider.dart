import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../models/group_chat_model.dart';
import '../services/community_service.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityService _communityService = CommunityService();

  List<CommunityModel> _communities = [];
  List<GroupChatModel> _groupChats = [];
  CommunityModel? _selectedCommunity;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommunityModel> get communities => _communities;
  List<GroupChatModel> get groupChats => _groupChats;
  CommunityModel? get selectedCommunity => _selectedCommunity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load user's communities
  void loadUserCommunities(String userId) {
    _communityService.getUserCommunities(userId).listen((communities) {
      _communities = communities;
      notifyListeners();
    });
  }

  // Create community
  Future<CommunityModel?> createCommunity({
    required String name,
    required String description,
    required String createdBy,
    String? communityImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      CommunityModel community = await _communityService.createCommunity(
        name: name,
        description: description,
        createdBy: createdBy,
        communityImageUrl: communityImageUrl,
      );
      _isLoading = false;
      notifyListeners();
      return community;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Join community
  Future<bool> joinCommunity({
    required String inviteCode,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityService.joinCommunity(
        inviteCode: inviteCode,
        userId: userId,
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

  // Select community
  void selectCommunity(CommunityModel community) {
    _selectedCommunity = community;
    loadCommunityGroupChats(community.id);
    notifyListeners();
  }

  // Load community's group chats
  void loadCommunityGroupChats(String communityId) {
    _communityService.getCommunityGroupChats(communityId).listen((groupChats) {
      _groupChats = groupChats;
      notifyListeners();
    });
  }

  // Create group chat
  Future<GroupChatModel?> createGroupChat({
    required String communityId,
    required String name,
    required String description,
    required String createdBy,
    bool isAnnouncementOnly = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      GroupChatModel groupChat = await _communityService.createGroupChat(
        communityId: communityId,
        name: name,
        description: description,
        createdBy: createdBy,
        isAnnouncementOnly: isAnnouncementOnly,
      );
      _isLoading = false;
      notifyListeners();
      return groupChat;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Remove member from community
  Future<bool> removeMember({
    required String communityId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityService.removeMemberFromCommunity(
        communityId: communityId,
        userId: userId,
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

  // Delete community
  Future<bool> deleteCommunity(String communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityService.deleteCommunity(communityId);
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

  // Regenerate invite code
  Future<String?> regenerateInviteCode(String communityId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String newCode = await _communityService.regenerateInviteCode(communityId);
      _isLoading = false;
      notifyListeners();
      return newCode;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear selected community
  void clearSelectedCommunity() {
    _selectedCommunity = null;
    _groupChats = [];
    notifyListeners();
  }
}
