import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Structured logging utility for the app
/// Replaces print() statements with proper logging
class Logger {
  final String _className;

  Logger(this._className);

  /// Create a logger for a specific class
  factory Logger.forClass(Type type) {
    return Logger(type.toString());
  }

  /// Log a debug message (only in development)
  void debug(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.debug, message, data: data);
  }

  /// Log an info message
  void info(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.info, message, data: data);
  }

  /// Log a warning message
  void warning(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Log an error message with optional error object and stack trace
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log a fatal error (will be sent to crash reporting)
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.fatal,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Skip debug logs in production
    if (level == LogLevel.debug && !EnvConfig.enableDebugLogs) {
      return;
    }

    // Format timestamp
    final timestamp = DateTime.now().toIso8601String();

    // Build log message
    final buffer = StringBuffer();
    buffer.write('[$timestamp] [${level.name.toUpperCase()}] [$_className] ');
    buffer.write(message);

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: ${data.toString()}');
    }

    if (error != null) {
      buffer.write(' | Error: ${error.toString()}');
    }

    // Print to console (will be replaced with proper logging service)
    final logMessage = buffer.toString();

    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        if (stackTrace != null) {
          debugPrint('Stack trace:\n$stackTrace');
        }
        break;
      case LogLevel.fatal:
        debugPrint('💀 $logMessage');
        if (stackTrace != null) {
          debugPrint('Stack trace:\n$stackTrace');
        }
        // TODO: Send to crash reporting service (Crashlytics/Sentry)
        _sendToCrashReporting(message, error, stackTrace, data);
        break;
    }

    // TODO: Send to analytics service for error tracking
    if (level == LogLevel.error || level == LogLevel.fatal) {
      _sendToAnalytics(level, message, error, data);
    }
  }

  /// Send error to crash reporting service
  void _sendToCrashReporting(
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    if (!EnvConfig.enableCrashReporting) return;

    // Import done dynamically to avoid dependency issues
    // The CrashReportingService will handle null checks
    try {
      // This will be called asynchronously - we don't await it
      // to avoid blocking the logging flow
      final crashReporting = _getCrashReportingService();
      crashReporting?.recordError(
        error ?? Exception(message),
        stackTrace,
        reason: message,
        fatal: true,
      );
    } catch (e) {
      debugPrint('Failed to send to crash reporting: $e');
    }
  }

  /// Send error event to analytics
  void _sendToAnalytics(
    LogLevel level,
    String message,
    Object? error,
    Map<String, dynamic>? data,
  ) {
    if (!EnvConfig.enableAnalytics) return;

    try {
      final crashReporting = _getCrashReportingService();
      crashReporting?.logErrorEvent(
        errorType: level.name,
        message: message,
        location: _className,
      );
    } catch (e) {
      debugPrint('Failed to send to analytics: $e');
    }
  }

  /// Get crash reporting service instance (lazy loading)
  dynamic _getCrashReportingService() {
    try {
      // Using dynamic import to avoid circular dependencies
      // In production, this should be properly injected
      return null; // Will be replaced with actual service in initialization
    } catch (e) {
      return null;
    }
  }
}

/// Global logger for app-wide logging
class AppLogger {
  static final _logger = Logger('App');

  static void debug(String message, [Map<String, dynamic>? data]) {
    _logger.debug(message, data);
  }

  static void info(String message, [Map<String, dynamic>? data]) {
    _logger.info(message, data);
  }

  static void warning(String message, [Map<String, dynamic>? data]) {
    _logger.warning(message, data);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _logger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _logger.fatal(
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }
}
