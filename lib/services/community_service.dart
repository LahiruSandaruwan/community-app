import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/community_model.dart';
import '../models/group_chat_model.dart';
import '../utils/constants.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      // Create community document
      DocumentReference communityRef =
          _firestore.collection(AppConstants.communitiesCollection).doc();

      CommunityModel community = CommunityModel(
        id: communityRef.id,
        name: name,
        description: description,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        communityImageUrl: communityImageUrl,
        memberIds: [createdBy], // Creator is first member
        adminIds: [createdBy], // Creator is admin
        groupChatIds: [],
        inviteCode: inviteCode,
        isActive: true,
      );

      await communityRef.set(community.toFirestore());

      // Add community to user's communityIds
      await _addCommunityToUser(createdBy, communityRef.id);

      // Create default announcement group
      await createGroupChat(
        communityId: communityRef.id,
        name: 'Announcements',
        description: 'Important announcements from tutors',
        createdBy: createdBy,
        isAnnouncementOnly: true,
      );

      return community;
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
      QuerySnapshot querySnapshot = await _firestore
          .collection(AppConstants.communitiesCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw AppConstants.errorInvalidInviteCode;
      }

      DocumentSnapshot communityDoc = querySnapshot.docs.first;
      CommunityModel community = CommunityModel.fromFirestore(communityDoc);

      // Check if user is already a member
      if (community.memberIds.contains(userId)) {
        throw 'You are already a member of this community';
      }

      // Add user to community
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(community.id)
          .update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      // Add community to user's communityIds
      await _addCommunityToUser(userId, community.id);

      // Add user to all group chats in the community
      for (String groupChatId in community.groupChatIds) {
        await _addMemberToGroupChat(groupChatId, userId);
      }

      return community.copyWith(
        memberIds: [...community.memberIds, userId],
      );
    } catch (e) {
      throw 'Failed to join community: $e';
    }
  }

  // Get user's communities
  Stream<List<CommunityModel>> getUserCommunities(String userId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .where('memberIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommunityModel.fromFirestore(doc)).toList());
  }

  // Get community by ID
  Future<CommunityModel?> getCommunityById(String communityId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return CommunityModel.fromFirestore(doc);
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

      // Create group chat document
      DocumentReference groupRef =
          _firestore.collection(AppConstants.groupChatsCollection).doc();

      GroupChatModel groupChat = GroupChatModel(
        id: groupRef.id,
        name: name,
        description: description,
        communityId: communityId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        memberIds: community.memberIds, // All community members
        isAnnouncementOnly: isAnnouncementOnly,
        isActive: true,
      );

      await groupRef.set(groupChat.toFirestore());

      // Add group chat ID to community
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'groupChatIds': FieldValue.arrayUnion([groupRef.id]),
      });

      return groupChat;
    } catch (e) {
      throw 'Failed to create group chat: $e';
    }
  }

  // Get community's group chats
  Stream<List<GroupChatModel>> getCommunityGroupChats(String communityId) {
    return _firestore
        .collection(AppConstants.groupChatsCollection)
        .where('communityId', isEqualTo: communityId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupChatModel.fromFirestore(doc))
            .toList());
  }

  // Get user's active group chats (across all communities)
  Stream<List<GroupChatModel>> getUserGroupChats(String userId) {
    return _firestore
        .collection(AppConstants.groupChatsCollection)
        .where('memberIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupChatModel.fromFirestore(doc))
            .toList());
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

      // Remove user from community
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });

      // Remove community from user's communityIds
      await _removeCommunityFromUser(userId, communityId);

      // Remove user from all group chats
      for (String groupChatId in community.groupChatIds) {
        await _removeMemberFromGroupChat(groupChatId, userId);
      }
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
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({'isActive': false});

      // Mark all group chats as inactive
      for (String groupChatId in community.groupChatIds) {
        await _firestore
            .collection(AppConstants.groupChatsCollection)
            .doc(groupChatId)
            .update({'isActive': false});
      }

      // Remove community from all users
      for (String userId in community.memberIds) {
        await _removeCommunityFromUser(userId, communityId);
      }
    } catch (e) {
      throw 'Failed to delete community: $e';
    }
  }

  // Regenerate invite code
  Future<String> regenerateInviteCode(String communityId) async {
    try {
      String newInviteCode = _generateInviteCode();

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({'inviteCode': newInviteCode});

      return newInviteCode;
    } catch (e) {
      throw 'Failed to regenerate invite code: $e';
    }
  }

  // Helper: Add community to user's communityIds
  Future<void> _addCommunityToUser(String userId, String communityId) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'communityIds': FieldValue.arrayUnion([communityId]),
    });
  }

  // Helper: Remove community from user's communityIds
  Future<void> _removeCommunityFromUser(String userId, String communityId) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'communityIds': FieldValue.arrayRemove([communityId]),
    });
  }

  // Helper: Add member to group chat
  Future<void> _addMemberToGroupChat(String groupChatId, String userId) async {
    await _firestore
        .collection(AppConstants.groupChatsCollection)
        .doc(groupChatId)
        .update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  // Helper: Remove member from group chat
  Future<void> _removeMemberFromGroupChat(String groupChatId, String userId) async {
    await _firestore
        .collection(AppConstants.groupChatsCollection)
        .doc(groupChatId)
        .update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  // Helper: Generate unique invite code
  String _generateInviteCode() {
    // Generate 8-character alphanumeric code
    String uuid = _uuid.v4().replaceAll('-', '').toUpperCase();
    return uuid.substring(0, 8);
  }
}
