/// Environment configuration for the app
/// Handles different environments (development, staging, production)
class EnvConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String _pocketbaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  /// Current environment
  static String get environment => _environment;

  /// PocketBase server URL
  /// For Android emulator, 10.0.2.2 maps to host machine's localhost
  static String get pocketbaseUrl {
    // Check if URL is localhost and return Android emulator compatible URL
    if (_pocketbaseUrl.contains('127.0.0.1') || _pocketbaseUrl.contains('localhost')) {
      return _pocketbaseUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }
    return _pocketbaseUrl;
  }

  /// Check if running in development mode
  static bool get isDevelopment => _environment == 'development';

  /// Check if running in staging mode
  static bool get isStaging => _environment == 'staging';

  /// Check if running in production mode
  static bool get isProduction => _environment == 'production';

  /// Firebase project configuration based on environment
  static String get firebaseProjectId {
    switch (_environment) {
      case 'production':
        return 'educonnect-prod';
      case 'staging':
        return 'educonnect-staging';
      default:
        return 'educonnect-dev';
    }
  }

  /// Log configuration
  static bool get enableDebugLogs => !isProduction;
  static bool get enableAnalytics => isProduction || isStaging;
  static bool get enableCrashReporting => isProduction || isStaging;

  /// Validate configuration
  static void validate() {
    if (isProduction && pocketbaseUrl.contains('localhost')) {
      throw Exception(
        'CRITICAL: Production build is using localhost URL. '
        'Set POCKETBASE_URL environment variable to production server.',
      );
    }

    if (isProduction && pocketbaseUrl.startsWith('http://')) {
      throw Exception(
        'CRITICAL: Production build must use HTTPS. '
        'Current URL: $pocketbaseUrl',
      );
    }
  }

  /// Print current configuration (for debugging)
  static void printConfig() {
    if (enableDebugLogs) {
      print('=== Environment Configuration ===');
      print('Environment: $environment');
      print('PocketBase URL: $pocketbaseUrl');
      print('Firebase Project: $firebaseProjectId');
      print('Debug Logs: $enableDebugLogs');
      print('Analytics: $enableAnalytics');
      print('Crash Reporting: $enableCrashReporting');
      print('================================');
    }
  }
}
