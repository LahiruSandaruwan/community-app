import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Rate limiter to prevent abuse of authentication and other sensitive endpoints
/// Implements a sliding window rate limiting algorithm
class RateLimiter {
  // Store timestamps of requests per identifier (e.g., email, user ID, IP)
  final Map<String, Queue<DateTime>> _requestHistory = {};

  // Configuration
  final int maxAttempts;
  final Duration timeWindow;
  final Duration blockDuration;

  // Track blocked identifiers
  final Map<String, DateTime> _blockedUntil = {};

  RateLimiter({
    this.maxAttempts = 5,
    this.timeWindow = const Duration(minutes: 15),
    this.blockDuration = const Duration(minutes: 30),
  });

  /// Check if a request from the given identifier should be allowed
  /// Returns null if allowed, otherwise returns a message with time remaining
  String? checkLimit(String identifier) {
    final now = DateTime.now();

    // Check if currently blocked
    if (_blockedUntil.containsKey(identifier)) {
      final blockedUntil = _blockedUntil[identifier]!;
      if (now.isBefore(blockedUntil)) {
        final remainingTime = blockedUntil.difference(now);
        final minutes = remainingTime.inMinutes;
        final seconds = remainingTime.inSeconds % 60;
        return 'Too many attempts. Try again in ${minutes}m ${seconds}s';
      } else {
        // Block duration has passed, remove from blocked list
        _blockedUntil.remove(identifier);
        _requestHistory.remove(identifier);
      }
    }

    // Get request history for this identifier
    if (!_requestHistory.containsKey(identifier)) {
      _requestHistory[identifier] = Queue<DateTime>();
    }

    final history = _requestHistory[identifier]!;

    // Remove old requests outside the time window
    final cutoff = now.subtract(timeWindow);
    while (history.isNotEmpty && history.first.isBefore(cutoff)) {
      history.removeFirst();
    }

    // Check if limit is exceeded
    if (history.length >= maxAttempts) {
      // Block the identifier
      _blockedUntil[identifier] = now.add(blockDuration);
      final minutes = blockDuration.inMinutes;
      return 'Too many attempts. Account temporarily blocked for $minutes minutes';
    }

    // Add current request to history
    history.add(now);

    // Request is allowed
    return null;
  }

  /// Reset the rate limit for a specific identifier (e.g., after successful login)
  void reset(String identifier) {
    _requestHistory.remove(identifier);
    _blockedUntil.remove(identifier);
  }

  /// Get remaining attempts for an identifier
  int getRemainingAttempts(String identifier) {
    if (_blockedUntil.containsKey(identifier)) {
      final blockedUntil = _blockedUntil[identifier]!;
      if (DateTime.now().isBefore(blockedUntil)) {
        return 0;
      }
    }

    if (!_requestHistory.containsKey(identifier)) {
      return maxAttempts;
    }

    final history = _requestHistory[identifier]!;
    final now = DateTime.now();
    final cutoff = now.subtract(timeWindow);

    // Count recent requests
    int recentRequests = 0;
    for (final timestamp in history) {
      if (timestamp.isAfter(cutoff)) {
        recentRequests++;
      }
    }

    return maxAttempts - recentRequests;
  }

  /// Check if an identifier is currently blocked
  bool isBlocked(String identifier) {
    if (!_blockedUntil.containsKey(identifier)) {
      return false;
    }

    final blockedUntil = _blockedUntil[identifier]!;
    if (DateTime.now().isBefore(blockedUntil)) {
      return true;
    }

    // Block has expired
    _blockedUntil.remove(identifier);
    return false;
  }

  /// Get the time when the block will be lifted
  DateTime? getBlockedUntil(String identifier) {
    if (!_blockedUntil.containsKey(identifier)) {
      return null;
    }

    final blockedUntil = _blockedUntil[identifier]!;
    if (DateTime.now().isBefore(blockedUntil)) {
      return blockedUntil;
    }

    return null;
  }

  /// Clear all rate limiting data (for testing purposes)
  void clearAll() {
    _requestHistory.clear();
    _blockedUntil.clear();
  }
}

/// Global rate limiters for different operations
class RateLimiters {
  // Authentication rate limiter (stricter)
  static final RateLimiter auth = RateLimiter(
    maxAttempts: 5,
    timeWindow: const Duration(minutes: 15),
    blockDuration: const Duration(minutes: 30),
  );

  // Password reset rate limiter
  static final RateLimiter passwordReset = RateLimiter(
    maxAttempts: 3,
    timeWindow: const Duration(hours: 1),
    blockDuration: const Duration(hours: 2),
  );

  // General API rate limiter (more lenient)
  static final RateLimiter api = RateLimiter(
    maxAttempts: 100,
    timeWindow: const Duration(minutes: 1),
    blockDuration: const Duration(minutes: 5),
  );

  // Message sending rate limiter (prevent spam)
  static final RateLimiter messaging = RateLimiter(
    maxAttempts: 30,
    timeWindow: const Duration(minutes: 1),
    blockDuration: const Duration(minutes: 5),
  );

  // File upload rate limiter
  static final RateLimiter fileUpload = RateLimiter(
    maxAttempts: 10,
    timeWindow: const Duration(minutes: 5),
    blockDuration: const Duration(minutes: 10),
  );

  /// Reset all rate limiters (for testing)
  static void resetAll() {
    auth.clearAll();
    passwordReset.clearAll();
    api.clearAll();
    messaging.clearAll();
    fileUpload.clearAll();
  }
}

/// Extension methods for easier rate limiting usage
extension RateLimitedOperation<T> on Future<T> Function() {
  /// Execute a function with rate limiting
  /// Returns the result if successful, throws RateLimitException if blocked
  Future<T> withRateLimit(
    RateLimiter limiter,
    String identifier, {
    VoidCallback? onSuccess,
  }) async {
    // Check rate limit
    final limitError = limiter.checkLimit(identifier);
    if (limitError != null) {
      throw RateLimitException(limitError);
    }

    try {
      // Execute the operation
      final result = await this();

      // Reset on success if callback provided
      if (onSuccess != null) {
        onSuccess();
        limiter.reset(identifier);
      }

      return result;
    } catch (e) {
      // Don't reset on failure - keep counting towards limit
      rethrow;
    }
  }
}

/// Exception thrown when rate limit is exceeded
class RateLimitException implements Exception {
  final String message;

  RateLimitException(this.message);

  @override
  String toString() => message;
}
