import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'pocketbase_service.dart';

class PocketBaseAuthService {
  final PocketBase _pb = PocketBaseService().client;

  // Get current user
  RecordModel? get currentUser => _pb.authStore.record;

  // Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;

  // Get current user ID
  String? get currentUserId => _pb.authStore.record?.id;

  // Auth state changes stream
  Stream<RecordModel?> get authStateChanges {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _pb.authStore.record;
    }).distinct();
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      // Create user in PocketBase
      final userData = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'role': role,
        'phoneNumber': phoneNumber ?? '',
        'emailVisibility': true,
        'createdAt': DateTime.now().toIso8601String(),
        'lastSeen': DateTime.now().toIso8601String(),
        'isOnline': true,
        'communityIds': [],
        'mutedGroupChatIds': [],
      };

      final record = await _pb.collection(AppConstants.usersCollection).create(
            body: userData,
          );

      // Authenticate the user after creation
      await _pb.collection(AppConstants.usersCollection).authWithPassword(
            email,
            password,
          );

      // Convert to UserModel
      final user = UserModel.fromPocketBase(record);

      // Save user data locally
      await _saveUserLocally(user);

      return user;
    } on ClientException catch (e) {
      throw _handlePocketBaseException(e);
    } catch (e) {
      throw 'An error occurred during sign up: $e';
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with PocketBase
      final authData = await _pb
          .collection(AppConstants.usersCollection)
          .authWithPassword(email, password);

      if (authData.record == null) {
        throw 'User profile not found. Please contact support or sign up again.';
      }

      // Convert to UserModel
      final user = UserModel.fromPocketBase(authData.record!);

      // Update online status
      await updateOnlineStatus(user.id, true);

      // Save user data locally
      await _saveUserLocally(user);

      return user;
    } on ClientException catch (e) {
      throw _handlePocketBaseException(e);
    } catch (e) {
      throw 'An error occurred during sign in: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (currentUserId != null) {
        await updateOnlineStatus(currentUserId!, false);
      }
      await _clearUserLocally();
      _pb.authStore.clear();
    } catch (e) {
      throw 'An error occurred during sign out: $e';
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final record = await _pb.collection(AppConstants.usersCollection).getOne(
            userId,
          );

      return UserModel.fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw 'Failed to get user data: ${e.response}';
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? profilePictureUrl,
    String? phoneNumber,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (profilePictureUrl != null) {
        updates['profilePictureUrl'] = profilePictureUrl;
      }
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;

      if (updates.isNotEmpty) {
        await _pb.collection(AppConstants.usersCollection).update(
              userId,
              body: updates,
            );
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _pb.collection(AppConstants.usersCollection).update(
        userId,
        body: {
          'isOnline': isOnline,
          'lastSeen': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silently fail - not critical
      print('Failed to update online status: $e');
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      await _pb.collection(AppConstants.usersCollection).update(
        userId,
        body: {'fcmToken': fcmToken},
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyFcmToken, fcmToken);
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // Mute group chat notifications
  Future<void> muteGroupChat(String userId, String groupChatId) async {
    try {
      // Get current user data
      final user = await getUserData(userId);
      if (user == null) return;

      // Add groupChatId to mutedGroupChatIds if not already present
      final mutedIds = List<String>.from(user.mutedGroupChatIds ?? []);
      if (!mutedIds.contains(groupChatId)) {
        mutedIds.add(groupChatId);
      }

      await _pb.collection(AppConstants.usersCollection).update(
        userId,
        body: {'mutedGroupChatIds': mutedIds},
      );
    } catch (e) {
      throw 'Failed to mute group chat: $e';
    }
  }

  // Unmute group chat notifications
  Future<void> unmuteGroupChat(String userId, String groupChatId) async {
    try {
      // Get current user data
      final user = await getUserData(userId);
      if (user == null) return;

      // Remove groupChatId from mutedGroupChatIds
      final mutedIds = List<String>.from(user.mutedGroupChatIds ?? []);
      mutedIds.remove(groupChatId);

      await _pb.collection(AppConstants.usersCollection).update(
        userId,
        body: {'mutedGroupChatIds': mutedIds},
      );
    } catch (e) {
      throw 'Failed to unmute group chat: $e';
    }
  }

  // Request password reset
  Future<void> resetPassword(String email) async {
    try {
      await _pb.collection(AppConstants.usersCollection).requestPasswordReset(
            email,
          );
    } on ClientException catch (e) {
      throw _handlePocketBaseException(e);
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  // Save user data locally
  Future<void> _saveUserLocally(UserModel user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserRole, user.role);
  }

  // Clear user data locally
  Future<void> _clearUserLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserRole);
  }

  // Handle PocketBase exceptions
  String _handlePocketBaseException(ClientException e) {
    final statusCode = e.statusCode;
    final response = e.response;

    // Try to extract error message from response
    if (response is Map && response.containsKey('message')) {
      final message = response['message'] as String;

      // Common error patterns
      if (message.contains('password')) {
        if (message.contains('weak') || message.contains('short')) {
          return 'The password is too weak';
        }
        return 'Incorrect password';
      }

      if (message.contains('email')) {
        if (message.contains('invalid')) {
          return 'Invalid email address';
        }
        if (message.contains('already')) {
          return 'An account already exists with this email';
        }
      }

      return message;
    }

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input';
      case 401:
        return 'Invalid email or password';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'No user found with this email';
      case 429:
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication error: ${e.response}';
    }
  }
}
