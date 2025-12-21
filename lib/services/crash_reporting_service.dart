import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Crash reporting and analytics service
/// Handles error tracking, crash reporting, and user analytics
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  FirebaseCrashlytics? _crashlytics;
  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  /// Initialize crash reporting and analytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (EnvConfig.enableCrashReporting) {
        _crashlytics = FirebaseCrashlytics.instance;

        // Enable automatic crash collection in production
        await _crashlytics!.setCrashlyticsCollectionEnabled(
          EnvConfig.isProduction || EnvConfig.isStaging,
        );

        // Set up Flutter error handling
        FlutterError.onError = (FlutterErrorDetails details) {
          _crashlytics!.recordFlutterFatalError(details);
        };

        // Catch errors outside Flutter framework
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics!.recordError(error, stack, fatal: true);
          return true;
        };

        debugPrint('✅ Crashlytics initialized');
      }

      if (EnvConfig.enableAnalytics) {
        _analytics = FirebaseAnalytics.instance;

        // Set analytics collection enabled
        await _analytics!.setAnalyticsCollectionEnabled(
          EnvConfig.isProduction || EnvConfig.isStaging,
        );

        debugPrint('✅ Analytics initialized');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ Error initializing crash reporting: $e');
      // Don't throw - app should continue even if crash reporting fails
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (_crashlytics == null || !EnvConfig.enableCrashReporting) {
      // Log to console in development
      debugPrint('❌ Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      return;
    }

    try {
      await _crashlytics!.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Failed to record error to Crashlytics: $e');
    }
  }

  /// Record a Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (_crashlytics == null || !EnvConfig.enableCrashReporting) {
      FlutterError.presentError(details);
      return;
    }

    try {
      await _crashlytics!.recordFlutterError(details);
    } catch (e) {
      debugPrint('Failed to record Flutter error to Crashlytics: $e');
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Failed to set user ID in Crashlytics: $e');
    }
  }

  /// Set custom key-value pairs for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.setCustomKey(key, value.toString());
    } catch (e) {
      debugPrint('Failed to set custom key in Crashlytics: $e');
    }
  }

  /// Log a message to crash reports
  Future<void> log(String message) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.log(message);
    } catch (e) {
      debugPrint('Failed to log message to Crashlytics: $e');
    }
  }

  // ========== Analytics Methods ==========

  /// Log a custom analytics event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (_analytics == null || !EnvConfig.enableAnalytics) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    } catch (e) {
      debugPrint('Failed to log analytics event: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null || !EnvConfig.enableAnalytics) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Set analytics user ID
  Future<void> setAnalyticsUserId(String? userId) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      debugPrint('Failed to set analytics user ID: $e');
    }
  }

  /// Set user property for analytics
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }

  /// Log login event
  Future<void> logLogin(String method) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  /// Log sign up event
  Future<void> logSignUp(String method) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': method},
    );
  }

  /// Log community creation
  Future<void> logCommunityCreated() async {
    await logEvent(name: 'community_created');
  }

  /// Log message sent
  Future<void> logMessageSent(String messageType) async {
    await logEvent(
      name: 'message_sent',
      parameters: {'message_type': messageType},
    );
  }

  /// Log assignment created
  Future<void> logAssignmentCreated() async {
    await logEvent(name: 'assignment_created');
  }

  /// Log poll created
  Future<void> logPollCreated() async {
    await logEvent(name: 'poll_created');
  }

  /// Log feature usage
  Future<void> logFeatureUsed(String featureName) async {
    await logEvent(
      name: 'feature_used',
      parameters: {'feature': featureName},
    );
  }

  /// Log error event
  Future<void> logErrorEvent({
    required String errorType,
    required String message,
    String? location,
  }) async {
    await logEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'message': message,
        if (location != null) 'location': location,
      },
    );
  }
}
