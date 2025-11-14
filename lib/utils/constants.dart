class AppConstants {
  // Collection names in Firestore
  static const String usersCollection = 'users';
  static const String communitiesCollection = 'communities';
  static const String groupChatsCollection = 'groupChats';
  static const String messagesCollection = 'messages';
  static const String inviteCodesCollection = 'inviteCodes';

  // User roles
  static const String roleTutor = 'tutor';
  static const String roleStudent = 'student';

  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVoice = 'voice';
  static const String messageTypeAnnouncement = 'announcement';
  static const String messageTypePoll = 'poll';
  static const String messageTypeQuiz = 'quiz';
  static const String messageTypeAssignment = 'assignment';

  // Storage paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String chatImagesPath = 'chat_images';

  // Shared preferences keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';

  // Limits
  static const int maxCommunityNameLength = 50;
  static const int maxGroupNameLength = 50;
  static const int maxMessageLength = 1000;
  static const int maxProfilePictureSize = 5 * 1024 * 1024; // 5MB
  static const int messagesPerPage = 50;

  // Error messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorPermission = 'Permission denied.';
  static const String errorInvalidInviteCode = 'Invalid or expired invite code.';
  static const String errorCommunityNotFound = 'Community not found.';
  static const String errorGroupNotFound = 'Group not found.';

  // Success messages
  static const String successCommunityCreated = 'Community created successfully!';
  static const String successGroupCreated = 'Group created successfully!';
  static const String successJoinedCommunity = 'Joined community successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successMessageSent = 'Message sent!';
}
