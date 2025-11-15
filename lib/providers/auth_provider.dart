import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/pocketbase_auth_service.dart';

class AuthProvider with ChangeNotifier {
  final PocketBaseAuthService _authService = PocketBaseAuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Initialize auth state
  Future<void> initializeAuth() async {
    try {
      if (_authService.isAuthenticated && _authService.currentUserId != null) {
        _currentUser = await _authService.getUserData(_authService.currentUserId!);
        notifyListeners();
      }
    } catch (e) {
      // Handle PocketBase initialization errors gracefully
      print('Error initializing auth: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
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

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
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

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? profilePictureUrl,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.id,
        name: name,
        profilePictureUrl: profilePictureUrl,
        phoneNumber: phoneNumber,
      );

      // Refresh user data
      _currentUser = await _authService.getUserData(_currentUser!.id);
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

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser != null) {
      await _authService.updateOnlineStatus(_currentUser!.id, isOnline);
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    if (_currentUser != null) {
      await _authService.updateFcmToken(_currentUser!.id, fcmToken);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
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

  // Reload current user data from PocketBase
  Future<void> loadCurrentUser() async {
    if (_currentUser == null) return;

    try {
      _currentUser = await _authService.getUserData(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
