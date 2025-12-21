import 'package:pocketbase/pocketbase.dart';
import '../config/env_config.dart';

/// Base PocketBase service that provides the PocketBase client instance
/// to all other services in the app
class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  late final PocketBase _pb;

  // PocketBase server URL - loaded from environment configuration
  static String get _baseUrl => EnvConfig.pocketbaseUrl;

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal() {
    _pb = PocketBase(_baseUrl);
  }

  /// Get the PocketBase client instance
  PocketBase get client => _pb;

  /// Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;

  /// Get current user ID
  String? get currentUserId => _pb.authStore.record?.id;

  /// Get current user record
  RecordModel? get currentUser => _pb.authStore.record;

  /// Clear authentication
  void clearAuth() {
    _pb.authStore.clear();
  }

  /// Note: PocketBase AuthStore auto-persists authentication state.
  /// No manual save() method is needed - authentication is automatically
  /// saved to secure storage when you authenticate via authWithPassword().
}
