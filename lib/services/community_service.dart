import 'package:pocketbase/pocketbase.dart';
import 'package:uuid/uuid.dart';
import '../models/community_model.dart';
import '../models/group_chat_model.dart';
import '../utils/constants.dart';
import 'pocketbase_service.dart';

class CommunityService {
  final PocketBase _pb = PocketBaseService().client;
  final Uuid _uuid = const Uuid();

  // Create a new community
  Future<CommunityModel> createCommunity({
    required String name,
    required String description,
    required String createdBy,
    String? communityImageUrl,
  }) async {
    try {
      // Generate unique invite code
      String inviteCode = _generateInviteCode();

      // Create community data
      final communityData = {
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'createdAt': DateTime.now().toIso8601String(),
        'communityImageUrl': communityImageUrl ?? '',
        'memberIds': [createdBy], // Creator is first member
        'adminIds': [createdBy], // Creator is admin
        'groupChatIds': [],
        'inviteCode': inviteCode,
        'isActive': true,
      };

      // Create community in PocketBase
      final record = await _pb
          .collection(AppConstants.communitiesCollection)
          .create(body: communityData);

      final community = CommunityModel.fromPocketBase(record);

      // Add community to user's communityIds
      await _addCommunityToUser(createdBy, record.id);

      // Create default announcement group
      await createGroupChat(
        communityId: record.id,
        name: 'Announcements',
        description: 'Important announcements from tutors',
        createdBy: createdBy,
        isAnnouncementOnly: true,
      );

      return community;
    } on ClientException catch (e) {
      throw 'Failed to create community: ${e.response}';
    } catch (e) {
      throw 'Failed to create community: $e';
    }
  }

  // Join community with invite code
  Future<CommunityModel> joinCommunity({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Find community with invite code
      final records = await _pb
          .collection(AppConstants.communitiesCollection)
          .getFullList(
            filter: 'inviteCode = "$inviteCode" && isActive = true',
          );

      if (records.isEmpty) {
        throw AppConstants.errorInvalidInviteCode;
      }

      final communityRecord = records.first;
      CommunityModel community = CommunityModel.fromPocketBase(communityRecord);

      // Check if user is already a member
      if (community.memberIds.contains(userId)) {
        throw 'You are already a member of this community';
      }

      // Add user to community memberIds (manual array operation)
      final updatedMemberIds = [...community.memberIds, userId];
      await _pb.collection(AppConstants.communitiesCollection).update(
        community.id,
        body: {'memberIds': updatedMemberIds},
      );

      // Add community to user's communityIds
      await _addCommunityToUser(userId, community.id);

      // Add user to all group chats in the community
      for (String groupChatId in community.groupChatIds) {
        await _addMemberToGroupChat(groupChatId, userId);
      }

      return community.copyWith(
        memberIds: updatedMemberIds,
      );
    } on ClientException catch (e) {
      throw 'Failed to join community: ${e.response}';
    } catch (e) {
      throw 'Failed to join community: $e';
    }
  }

  // Get user's communities
  Stream<List<CommunityModel>> getUserCommunities(String userId) async* {
    // Initial fetch
    List<CommunityModel> communities = await _fetchUserCommunities(userId);
    yield communities;

    // Track consecutive errors for backoff
    int consecutiveErrors = 0;

    // Subscribe to real-time updates
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      try {
        communities = await _fetchUserCommunities(userId);
        yield communities;
        consecutiveErrors = 0; // Reset on success
      } catch (e) {
        consecutiveErrors++;
        // After 3 consecutive errors, throw to notify the UI
        if (consecutiveErrors >= 3) {
          throw 'Failed to sync communities after multiple attempts. Please check your connection.';
        }
        // Continue with previous data on first few errors
        yield communities;
      }
    }
  }

  // Helper method to fetch user communities
  Future<List<CommunityModel>> _fetchUserCommunities(String userId) async {
    try {
      final records = await _pb
          .collection(AppConstants.communitiesCollection)
          .getFullList(
            filter: 'memberIds ~ "$userId" && isActive = true',
            sort: '-createdAt',
          );

      return records.map((record) => CommunityModel.fromPocketBase(record)).toList();
    } catch (e) {
      throw 'Failed to fetch user communities: $e';
    }
  }

  // Get community by ID
  Future<CommunityModel?> getCommunityById(String communityId) async {
    try {
      final record = await _pb
          .collection(AppConstants.communitiesCollection)
          .getOne(communityId);

      return CommunityModel.fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw 'Failed to get community: ${e.response}';
    } catch (e) {
      throw 'Failed to get community: $e';
    }
  }

  // Create a group chat within a community
  Future<GroupChatModel> createGroupChat({
    required String communityId,
    required String name,
    required String description,
    required String createdBy,
    bool isAnnouncementOnly = false,
  }) async {
    try {
      // Get community to access member list
      CommunityModel? community = await getCommunityById(communityId);
      if (community == null) {
        throw AppConstants.errorCommunityNotFound;
      }

      // Create group chat data
      final groupChatData = {
        'name': name,
        'description': description,
        'communityId': communityId,
        'createdBy': createdBy,
        'createdAt': DateTime.now().toIso8601String(),
        'groupImageUrl': '',
        'memberIds': community.memberIds, // All community members
        'isAnnouncementOnly': isAnnouncementOnly,
        'lastMessageAt': '',
        'lastMessage': '',
        'lastMessageSenderId': '',
        'unreadCounts': {},
        'pinnedMessageIds': [],
        'isActive': true,
      };

      // Create group chat in PocketBase
      final record = await _pb
          .collection(AppConstants.groupChatsCollection)
          .create(body: groupChatData);

      final groupChat = GroupChatModel.fromPocketBase(record);

      // Add group chat ID to community (manual array operation)
      final updatedGroupChatIds = [...community.groupChatIds, record.id];
      await _pb.collection(AppConstants.communitiesCollection).update(
        communityId,
        body: {'groupChatIds': updatedGroupChatIds},
      );

      return groupChat;
    } on ClientException catch (e) {
      throw 'Failed to create group chat: ${e.response}';
    } catch (e) {
      throw 'Failed to create group chat: $e';
    }
  }

  // Get community's group chats
  Stream<List<GroupChatModel>> getCommunityGroupChats(String communityId) async* {
    // Initial fetch
    List<GroupChatModel> groupChats = await _fetchCommunityGroupChats(communityId);
    yield groupChats;

    // Track consecutive errors for backoff
    int consecutiveErrors = 0;

    // Subscribe to real-time updates
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      try {
        groupChats = await _fetchCommunityGroupChats(communityId);
        yield groupChats;
        consecutiveErrors = 0; // Reset on success
      } catch (e) {
        consecutiveErrors++;
        // After 3 consecutive errors, throw to notify the UI
        if (consecutiveErrors >= 3) {
          throw 'Failed to sync group chats after multiple attempts. Please check your connection.';
        }
        // Continue with previous data on first few errors
        yield groupChats;
      }
    }
  }

  // Helper method to fetch community group chats
  Future<List<GroupChatModel>> _fetchCommunityGroupChats(String communityId) async {
    try {
      final records = await _pb
          .collection(AppConstants.groupChatsCollection)
          .getFullList(
            filter: 'communityId = "$communityId" && isActive = true',
            sort: 'createdAt',
          );

      return records.map((record) => GroupChatModel.fromPocketBase(record)).toList();
    } catch (e) {
      throw 'Failed to fetch community group chats: $e';
    }
  }

  // Get user's active group chats (across all communities)
  Stream<List<GroupChatModel>> getUserGroupChats(String userId) async* {
    // Initial fetch
    List<GroupChatModel> groupChats = await _fetchUserGroupChats(userId);
    yield groupChats;

    // Track consecutive errors for backoff
    int consecutiveErrors = 0;

    // Subscribe to real-time updates
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      try {
        groupChats = await _fetchUserGroupChats(userId);
        yield groupChats;
        consecutiveErrors = 0; // Reset on success
      } catch (e) {
        consecutiveErrors++;
        // After 3 consecutive errors, throw to notify the UI
        if (consecutiveErrors >= 3) {
          throw 'Failed to sync group chats after multiple attempts. Please check your connection.';
        }
        // Continue with previous data on first few errors
        yield groupChats;
      }
    }
  }

  // Helper method to fetch user group chats
  Future<List<GroupChatModel>> _fetchUserGroupChats(String userId) async {
    try {
      final records = await _pb
          .collection(AppConstants.groupChatsCollection)
          .getFullList(
            filter: 'memberIds ~ "$userId" && isActive = true',
            sort: '-lastMessageAt',
          );

      return records.map((record) => GroupChatModel.fromPocketBase(record)).toList();
    } catch (e) {
      throw 'Failed to fetch user group chats: $e';
    }
  }

  // Remove member from community
  Future<void> removeMemberFromCommunity({
    required String communityId,
    required String userId,
  }) async {
    try {
      CommunityModel? community = await getCommunityById(communityId);
      if (community == null) {
        throw AppConstants.errorCommunityNotFound;
      }

      // Remove user from community memberIds (manual array operation)
      final updatedMemberIds = community.memberIds.where((id) => id != userId).toList();
      await _pb.collection(AppConstants.communitiesCollection).update(
        communityId,
        body: {'memberIds': updatedMemberIds},
      );

      // Remove community from user's communityIds
      await _removeCommunityFromUser(userId, communityId);

      // Remove user from all group chats
      for (String groupChatId in community.groupChatIds) {
        await _removeMemberFromGroupChat(groupChatId, userId);
      }
    } on ClientException catch (e) {
      throw 'Failed to remove member: ${e.response}';
    } catch (e) {
      throw 'Failed to remove member: $e';
    }
  }

  // Delete community (admin only)
  Future<void> deleteCommunity(String communityId) async {
    try {
      CommunityModel? community = await getCommunityById(communityId);
      if (community == null) {
        throw AppConstants.errorCommunityNotFound;
      }

      // Mark community as inactive
      await _pb.collection(AppConstants.communitiesCollection).update(
        communityId,
        body: {'isActive': false},
      );

      // Mark all group chats as inactive
      for (String groupChatId in community.groupChatIds) {
        await _pb.collection(AppConstants.groupChatsCollection).update(
          groupChatId,
          body: {'isActive': false},
        );
      }

      // Remove community from all users
      for (String userId in community.memberIds) {
        await _removeCommunityFromUser(userId, communityId);
      }
    } on ClientException catch (e) {
      throw 'Failed to delete community: ${e.response}';
    } catch (e) {
      throw 'Failed to delete community: $e';
    }
  }

  // Make user an admin
  Future<void> makeAdmin({
    required String communityId,
    required String userId,
  }) async {
    try {
      // Get current community data
      CommunityModel? community = await getCommunityById(communityId);
      if (community == null) {
        throw AppConstants.errorCommunityNotFound;
      }

      // Add userId to adminIds if not already present (manual array operation)
      if (!community.adminIds.contains(userId)) {
        final updatedAdminIds = [...community.adminIds, userId];
        await _pb.collection(AppConstants.communitiesCollection).update(
          communityId,
          body: {'adminIds': updatedAdminIds},
        );
      }
    } on ClientException catch (e) {
      throw 'Failed to make user admin: ${e.response}';
    } catch (e) {
      throw 'Failed to make user admin: $e';
    }
  }

  // Remove admin privileges
  Future<void> removeAdmin({
    required String communityId,
    required String userId,
  }) async {
    try {
      // Check if this is the last admin
      CommunityModel? community = await getCommunityById(communityId);
      if (community == null) {
        throw AppConstants.errorCommunityNotFound;
      }

      if (community.adminIds.length <= 1) {
        throw 'Cannot remove the last admin. Community must have at least one admin.';
      }

      // Remove userId from adminIds (manual array operation)
      final updatedAdminIds = community.adminIds.where((id) => id != userId).toList();
      await _pb.collection(AppConstants.communitiesCollection).update(
        communityId,
        body: {'adminIds': updatedAdminIds},
      );
    } on ClientException catch (e) {
      throw 'Failed to remove admin: ${e.response}';
    } catch (e) {
      throw 'Failed to remove admin: $e';
    }
  }

  // Regenerate invite code
  Future<String> regenerateInviteCode(String communityId) async {
    try {
      String newInviteCode = _generateInviteCode();

      await _pb.collection(AppConstants.communitiesCollection).update(
        communityId,
        body: {'inviteCode': newInviteCode},
      );

      return newInviteCode;
    } on ClientException catch (e) {
      throw 'Failed to regenerate invite code: ${e.response}';
    } catch (e) {
      throw 'Failed to regenerate invite code: $e';
    }
  }

  // Helper: Add community to user's communityIds
  Future<void> _addCommunityToUser(String userId, String communityId) async {
    try {
      // Get current user data
      final userRecord = await _pb
          .collection(AppConstants.usersCollection)
          .getOne(userId);

      final communityIds = List<String>.from(userRecord.data['communityIds'] ?? []);

      // Add communityId if not already present
      if (!communityIds.contains(communityId)) {
        communityIds.add(communityId);
        await _pb.collection(AppConstants.usersCollection).update(
          userId,
          body: {'communityIds': communityIds},
        );
      }
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw 'User not found. Cannot add community membership.';
      }
      throw 'Failed to add community to user: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to add community to user: $e';
    }
  }

  // Helper: Remove community from user's communityIds
  Future<void> _removeCommunityFromUser(String userId, String communityId) async {
    try {
      // Get current user data
      final userRecord = await _pb
          .collection(AppConstants.usersCollection)
          .getOne(userId);

      final communityIds = List<String>.from(userRecord.data['communityIds'] ?? []);

      // Remove communityId
      communityIds.remove(communityId);
      await _pb.collection(AppConstants.usersCollection).update(
        userId,
        body: {'communityIds': communityIds},
      );
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        // User already deleted, nothing to update
        return;
      }
      throw 'Failed to remove community from user: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to remove community from user: $e';
    }
  }

  // Helper: Add member to group chat
  Future<void> _addMemberToGroupChat(String groupChatId, String userId) async {
    try {
      // Get current group chat data
      final groupChatRecord = await _pb
          .collection(AppConstants.groupChatsCollection)
          .getOne(groupChatId);

      final memberIds = List<String>.from(groupChatRecord.data['memberIds'] ?? []);

      // Add userId if not already present
      if (!memberIds.contains(userId)) {
        memberIds.add(userId);
        await _pb.collection(AppConstants.groupChatsCollection).update(
          groupChatId,
          body: {'memberIds': memberIds},
        );
      }
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw 'Group chat not found. Cannot add member.';
      }
      throw 'Failed to add member to group chat: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to add member to group chat: $e';
    }
  }

  // Helper: Remove member from group chat
  Future<void> _removeMemberFromGroupChat(String groupChatId, String userId) async {
    try {
      // Get current group chat data
      final groupChatRecord = await _pb
          .collection(AppConstants.groupChatsCollection)
          .getOne(groupChatId);

      final memberIds = List<String>.from(groupChatRecord.data['memberIds'] ?? []);

      // Remove userId
      memberIds.remove(userId);
      await _pb.collection(AppConstants.groupChatsCollection).update(
        groupChatId,
        body: {'memberIds': memberIds},
      );
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        // Group chat already deleted, nothing to update
        return;
      }
      throw 'Failed to remove member from group chat: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to remove member from group chat: $e';
    }
  }

  // Helper: Generate unique invite code
  String _generateInviteCode() {
    // Generate 8-character alphanumeric code
    String uuid = _uuid.v4().replaceAll('-', '').toUpperCase();
    return uuid.substring(0, 8);
  }
}
