# EduConnect - Production Readiness Implementation Guide

This document outlines the critical and high-priority improvements made to make EduConnect production-ready, along with implementation guides for remaining features.

---

## ✅ COMPLETED IMPLEMENTATIONS

### 1. Environment Configuration System ✅

**Status:** COMPLETE

**What was implemented:**
- [lib/config/env_config.dart](lib/config/env_config.dart) - Environment configuration class
- [BUILD_CONFIG.md](BUILD_CONFIG.md) - Build configuration guide
- [.env.example](.env.example) - Environment variable template
- Updated [lib/services/pocketbase_service.dart](lib/services/pocketbase_service.dart) to use environment config
- Updated [lib/main.dart](lib/main.dart) with environment validation

**Features:**
- Support for development, staging, and production environments
- Compile-time environment variables using `--dart-define`
- Automatic validation (prevents localhost in production)
- HTTPS enforcement in production
- Configuration printing in debug mode

**Usage:**
```bash
# Development (default)
flutter run

# Production
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=POCKETBASE_URL=https://api.educonnect.com
```

**Security improvements:**
- ✅ No hardcoded URLs
- ✅ Production build validation
- ✅ HTTPS enforcement
- ✅ Environment-specific configuration

---

### 2. Structured Logging System ✅

**Status:** COMPLETE

**What was implemented:**
- [lib/utils/logger.dart](lib/utils/logger.dart) - Comprehensive logging utility
- Log levels: debug, info, warning, error, fatal
- Class-specific loggers with `Logger.forClass(Type)`
- Global `AppLogger` for app-wide logging
- Integration hooks for crash reporting and analytics

**Features:**
- Structured log messages with timestamps
- Log level filtering (debug logs disabled in production)
- Error tracking with stack traces
- Crash reporting integration (ready for Crashlytics)
- Analytics integration hooks

**Usage:**
```dart
// In a class
class MyService {
  final Logger _logger = Logger.forClass(MyService);

  void doSomething() {
    _logger.info('Starting operation');
    try {
      // ... operation
      _logger.debug('Debug details', {'key': 'value'});
    } catch (e, stack) {
      _logger.error('Operation failed', error: e, stackTrace: stack);
    }
  }
}

// Global usage
AppLogger.info('App started');
AppLogger.error('Critical error', error: e, stackTrace: stack);
```

**Replaced:** All `print()` statements should be replaced with logger calls

**Example migration:**
```dart
// OLD
print('Error: $e');

// NEW
_logger.error('Operation failed', error: e);
```

---

### 3. Firebase Crashlytics & Analytics ✅

**Status:** COMPLETE (Configuration Required)

**What was implemented:**
- [lib/services/crash_reporting_service.dart](lib/services/crash_reporting_service.dart)
- Firebase Core, Crashlytics, and Analytics added to pubspec.yaml
- [lib/firebase_options.dart](lib/firebase_options.dart) - Placeholder configuration
- Integration in [lib/main.dart](lib/main.dart)
- Automatic Flutter error catching
- Platform error catching

**Features:**
- Automatic crash reporting
- Non-fatal error recording
- Custom analytics events
- Screen view tracking
- User identification for crash reports
- Feature usage tracking

**Setup Required:**
1. Run `flutterfire configure` to generate proper firebase_options.dart
2. Ensure Firebase project exists (or create new one)
3. Enable Crashlytics and Analytics in Firebase Console
4. Replace placeholder values in firebase_options.dart

**Usage:**
```dart
final crashReporting = CrashReportingService();

// Record non-fatal error
await crashReporting.recordError(error, stackTrace, reason: 'Failed to load');

// Log analytics event
await crashReporting.logEvent(
  name: 'feature_used',
  parameters: {'feature': 'chat'},
);

// Log screen view
await crashReporting.logScreenView(screenName: 'ChatScreen');

// Set user context
await crashReporting.setUserId(userId);
```

**Pre-built analytics methods:**
- `logLogin(method)` - User login
- `logSignUp(method)` - User registration
- `logCommunityCreated()` - Community creation
- `logMessageSent(messageType)` - Message sent
- `logAssignmentCreated()` - Assignment created
- `logPollCreated()` - Poll created
- `logFeatureUsed(featureName)` - Feature usage
- `logErrorEvent()` - Error tracking

---

### 4. Rate Limiting System ✅

**Status:** COMPLETE

**What was implemented:**
- [lib/utils/rate_limiter.dart](lib/utils/rate_limiter.dart) - Sliding window rate limiter
- Integration in [lib/services/pocketbase_auth_service.dart](lib/services/pocketbase_auth_service.dart)
- Multiple rate limiter instances for different operations

**Features:**
- Sliding window algorithm
- Configurable limits, time windows, and block durations
- Automatic blocking after exceeding limits
- Remaining attempts tracking
- Automatic reset on successful operations

**Available Rate Limiters:**
```dart
// Authentication (5 attempts in 15 min, block 30 min)
RateLimiters.auth

// Password reset (3 attempts in 1 hour, block 2 hours)
RateLimiters.passwordReset

// General API (100 attempts in 1 min, block 5 min)
RateLimiters.api

// Messaging (30 messages in 1 min, block 5 min)
RateLimiters.messaging

// File upload (10 uploads in 5 min, block 10 min)
RateLimiters.fileUpload
```

**Usage:**
```dart
// Check rate limit
final error = RateLimiters.auth.checkLimit(email);
if (error != null) {
  throw error; // "Too many attempts. Try again in 5m 30s"
}

// On success, reset the limit
RateLimiters.auth.reset(email);

// Check remaining attempts
int remaining = RateLimiters.auth.getRemainingAttempts(email);

// Check if blocked
bool blocked = RateLimiters.auth.isBlocked(email);
```

**Applied to:**
- ✅ Sign up
- ✅ Sign in
- TODO: Password reset
- TODO: Message sending
- TODO: File uploads

---

### 5. Secure Storage ✅

**Status:** COMPLETE

**What was implemented:**
- [lib/utils/secure_storage.dart](lib/utils/secure_storage.dart)
- Flutter Secure Storage added to pubspec.yaml
- Platform-specific encryption (Keychain on iOS, KeyStore on Android)

**Features:**
- Secure key-value storage
- Encrypted shared preferences on Android
- Keychain integration on iOS
- Session management methods
- Authentication token storage
- User data protection

**Usage:**
```dart
final storage = SecureStorage();

// Save auth token
await storage.saveAuthToken(token);

// Save complete user session
await storage.saveUserSession(
  userId: user.id,
  email: user.email,
  authToken: token,
);

// Check if session exists
bool hasSession = await storage.hasUserSession();

// Clear session (logout)
await storage.clearUserSession();

// Custom key-value
await storage.write('custom_key', 'sensitive_value');
String? value = await storage.read('custom_key');
```

**TODO Integration:**
- Replace SharedPreferences with SecureStorage for sensitive data
- Update auth service to use secure storage for tokens
- Migrate existing token storage

---

## 🚧 REMAINING HIGH-PRIORITY IMPLEMENTATIONS

### 6. Password Strength Validation

**Status:** NOT IMPLEMENTED

**What needs to be done:**
1. Create `lib/utils/validators.dart` with password strength checker
2. Add to sign-up form validation
3. Show real-time strength indicator in UI
4. Enforce minimum requirements

**Implementation guide:**

```dart
// lib/utils/validators.dart
class Validators {
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }

    if (value.length > maxPasswordLength) {
      return 'Password is too long';
    }

    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null; // Valid
  }

  static PasswordStrength getPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name is too long';
    }

    return null;
  }
}

enum PasswordStrength { weak, medium, strong }
```

**UI Integration:**
```dart
// In signup_screen.dart
TextFormField(
  controller: _passwordController,
  validator: Validators.validatePassword,
  onChanged: (value) {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(value);
    });
  },
  // ... other properties
)

// Show strength indicator
if (_passwordController.text.isNotEmpty)
  PasswordStrengthIndicator(strength: _passwordStrength),
```

---

### 7. Input Validation & Sanitization

**Status:** PARTIAL

**What needs to be done:**
1. Complete validators.dart with all input types
2. Add XSS prevention for text inputs
3. Add file validation (size, type, content)
4. Implement form-wide validation

**Additional validators needed:**

```dart
// lib/utils/validators.dart (additions)
class Validators {
  // ... existing validators ...

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? validateCommunityName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Community name is required';
    }

    if (value.length < 3) {
      return 'Community name must be at least 3 characters';
    }

    if (value.length > 50) {
      return 'Community name is too long';
    }

    // No special characters except spaces, hyphens, underscores
    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(value)) {
      return 'Community name contains invalid characters';
    }

    return null;
  }

  static String? validateMessage(String? value, {int maxLength = 5000}) {
    if (value == null || value.isEmpty) {
      return 'Message cannot be empty';
    }

    if (value.trim().isEmpty) {
      return 'Message cannot be only whitespace';
    }

    if (value.length > maxLength) {
      return 'Message is too long (max $maxLength characters)';
    }

    return null;
  }

  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .trim();
  }

  static bool isValidFileType(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  static bool isValidFileSize(int fileSize, int maxSizeInBytes) {
    return fileSize <= maxSizeInBytes;
  }
}
```

---

### 8. FCM Push Notifications

**Status:** PARTIALLY CONFIGURED

**What's missing:**
1. FCM message handling service
2. Notification display logic
3. Background notification handlers
4. Notification permission requests
5. Notification action handlers

**Implementation guide:**

```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger.forClass(NotificationService);
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _logger.warning('Notification permission denied');
        return;
      }

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        _logger.info('FCM Token: $token');
        await SecureStorage().saveFcmToken(token);
        // TODO: Send token to backend
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen((token) {
        _logger.info('FCM Token refreshed: $token');
        SecureStorage().saveFcmToken(token);
        // TODO: Send token to backend
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

      _initialized = true;
      _logger.info('Notification service initialized');
    } catch (e) {
      _logger.error('Failed to initialize notifications', error: e);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.info('Foreground message: ${message.notification?.title}');

    // Show local notification
    await _showNotification(
      title: message.notification?.title ?? 'New message',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  Future<void> _handleNotificationOpened(RemoteMessage message) async {
    _logger.info('Notification opened: ${message.messageId}');
    // TODO: Navigate to appropriate screen
  }

  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
    // TODO: Handle notification tap
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'educonnect_channel',
      'EduConnect Notifications',
      channelDescription: 'Notifications for messages and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
```

**Required package additions:**
```yaml
# pubspec.yaml
firebase_messaging: ^15.0.0
flutter_local_notifications: ^17.0.0
```

**Integration in main.dart:**
```dart
void main() async {
  // ... existing initialization ...

  // Initialize notifications
  await NotificationService().initialize();

  runApp(const EduConnectApp());
}
```

---

### 9. Unit & Widget Tests

**Status:** NOT IMPLEMENTED

**What needs to be done:**
1. Set up test infrastructure
2. Create unit tests for services
3. Create widget tests for screens
4. Create integration tests for critical flows
5. Set up test coverage reporting

**Implementation guide:**

```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/services/pocketbase_auth_service.dart';
import 'package:educonnect/utils/rate_limiter.dart';

void main() {
  group('PocketBaseAuthService', () {
    late PocketBaseAuthService authService;

    setUp(() {
      authService = PocketBaseAuthService();
      RateLimiters.resetAll(); // Reset rate limiters before each test
    });

    group('Sign Up', () {
      test('should reject weak password', () async {
        expect(
          () => authService.signUpWithEmail(
            email: 'test@example.com',
            password: '123', // Weak password
            name: 'Test User',
            role: 'student',
          ),
          throwsA(isA<String>()),
        );
      });

      test('should enforce rate limiting', () async {
        final email = 'ratelimit@example.com';

        // Make max attempts
        for (int i = 0; i < 5; i++) {
          RateLimiters.auth.checkLimit(email);
        }

        // Next attempt should be blocked
        final error = RateLimiters.auth.checkLimit(email);
        expect(error, isNotNull);
        expect(error, contains('Too many attempts'));
      });
    });
  });
}

// test/widgets/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:educonnect/screens/auth/login_screen.dart';
import 'package:educonnect/providers/auth_provider.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('should display email and password fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should show error for invalid email', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email',
      );

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });
}
```

**Test coverage setup:**
```yaml
# pubspec.yaml dev_dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
  flutter_lints: ^3.0.1
```

**Run tests:**
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

### 10. Voice Message Recording

**Status:** SERVICE EXISTS, INTEGRATION DISABLED

**What needs to be done:**
1. Re-enable voice message recording in chat_screen.dart
2. Test permission handling
3. Add recording UI with waveform
4. Implement playback controls
5. Add recording time limit

**Implementation:**

Uncomment and update in chat_screen.dart:
```dart
// Uncomment lines 12-13, 37-38, 53-54

IconButton(
  icon: const Icon(Icons.mic),
  onPressed: _isRecording ? _stopRecording : _startRecording,
  color: _isRecording ? Colors.red : null,
),

// Ensure VoiceMessageService is properly initialized
```

**Enhanced recording UI:**
```dart
// lib/widgets/voice_recording_widget.dart
class VoiceRecordingWidget extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String path, Duration duration) onComplete;

  const VoiceRecordingWidget({
    required this.onCancel,
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget> {
  late VoiceMessageService _voiceService;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceMessageService();
    _startRecording();
  }

  Future<void> _startRecording() async {
    await _voiceService.startRecording();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _duration = Duration(milliseconds: timer.tick * 100);
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _voiceService.stopRecording();
    if (path != null) {
      widget.onComplete(path, _duration);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _voiceService.cancelRecording();
              widget.onCancel();
            },
          ),
          const SizedBox(width: 8),
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 8),
          Text('$minutes:$seconds'),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: _duration.inSeconds / 60, // Max 60 seconds
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _stopRecording,
          ),
        ],
      ),
    );
  }
}
```

---

### 11. File Upload (Fix v1 Embedding Issue)

**Status:** DISABLED

**Problem:** `file_picker` package has v1 embedding compatibility issues

**Solution options:**

**Option 1: Migrate to v2 embedding (Recommended)**

Update android/app/src/main/AndroidManifest.xml:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:label="educonnect">
    <activity
      android:name=".MainActivity"
      android:exported="true"
      android:launchMode="singleTop"
      android:theme="@style/LaunchTheme"
      android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
      android:hardwareAccelerated="true"
      android:windowSoftInputMode="adjustResize">
      <!-- Remove any android:name="io.flutter.embedding.android.FlutterActivity" -->
      <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme" />
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
    <meta-data
      android:name="flutterEmbedding"
      android:value="2" />
  </application>
</manifest>
```

Update android/app/src/main/kotlin/.../MainActivity.kt:
```kotlin
package com.example.educonnect

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
```

Then uncomment in pubspec.yaml:
```yaml
file_picker: ^6.1.1
```

**Option 2: Use alternative package**
```yaml
# Replace file_picker with:
file_selector: ^1.0.3  # Cross-platform file selector
image_picker: ^1.0.7   # Already installed for images
```

---

### 12. Quiz Feature Implementation

**Status:** NOT IMPLEMENTED (Only constants exist)

**Full implementation required:**

1. **Create Quiz Model:**

```dart
// lib/models/quiz_model.dart
class QuizModel {
  final String id;
  final String communityId;
  final String groupChatId;
  final String createdBy;
  final String title;
  final String? description;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int timeLimit; // seconds
  final bool shuffleQuestions;
  final bool showCorrectAnswers;
  final double passingScore; // percentage

  QuizModel({
    required this.id,
    required this.communityId,
    required this.groupChatId,
    required this.createdBy,
    required this.title,
    this.description,
    required this.questions,
    required this.createdAt,
    this.dueDate,
    this.timeLimit = 600, // 10 minutes default
    this.shuffleQuestions = false,
    this.showCorrectAnswers = true,
    this.passingScore = 70.0,
  });

  // Add fromFirestore, toFirestore, copyWith methods
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final List<int> correctAnswers; // Indices of correct options
  final int points;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswers,
    this.points = 1,
    this.explanation,
  });
}

enum QuestionType {
  multipleChoice,
  multipleSelect,
  trueFalse,
}

class QuizSubmission {
  final String id;
  final String quizId;
  final String userId;
  final Map<String, List<int>> answers; // questionId -> selected answer indices
  final DateTime submittedAt;
  final Duration timeTaken;
  final double score;
  final bool passed;

  QuizSubmission({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.answers,
    required this.submittedAt,
    required this.timeTaken,
    required this.score,
    required this.passed,
  });
}
```

2. **Create Quiz Service:**

```dart
// lib/services/quiz_service.dart
class QuizService {
  final PocketBase _pb = PocketBaseService().client;
  final Logger _logger = Logger.forClass(QuizService);

  Future<QuizModel> createQuiz(QuizModel quiz) async {
    // Implementation
  }

  Stream<List<QuizModel>> getQuizzesForGroup(String groupChatId) {
    // Implementation
  }

  Future<QuizSubmission> submitQuiz(
    String quizId,
    Map<String, List<int>> answers,
  ) async {
    // Calculate score, create submission
  }

  Future<List<QuizSubmission>> getSubmissions(String quizId) async {
    // Get all submissions for a quiz
  }
}
```

3. **Create Quiz Provider:**

```dart
// lib/providers/quiz_provider.dart
class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();

  List<QuizModel> _quizzes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Implement methods for creating, fetching, submitting quizzes
}
```

4. **Create Quiz UI:**
- `lib/screens/quiz/quiz_list_screen.dart`
- `lib/screens/quiz/quiz_detail_screen.dart`
- `lib/screens/quiz/create_quiz_screen.dart`
- `lib/screens/quiz/take_quiz_screen.dart`
- `lib/screens/quiz/quiz_results_screen.dart`
- `lib/widgets/quiz_question_widget.dart`

---

### 13. Offline Message Queue & Sync

**Status:** NOT IMPLEMENTED

**Implementation guide:**

```dart
// lib/services/offline_message_queue.dart
class OfflineMessageQueue {
  static final OfflineMessageQueue _instance = OfflineMessageQueue._internal();
  factory OfflineMessageQueue() => _instance;
  OfflineMessageQueue._internal();

  final Logger _logger = Logger.forClass(OfflineMessageQueue);
  final Queue<PendingMessage> _queue = Queue();
  bool _isSyncing = false;

  // Add message to queue
  Future<void> enqueue(PendingMessage message) async {
    _queue.add(message);
    await _saveQueue();
    _logger.info('Message queued for offline sync: ${message.id}');
  }

  // Sync all pending messages
  Future<void> sync() async {
    if (_isSyncing || _queue.isEmpty) return;

    _isSyncing = true;
    _logger.info('Starting offline sync: ${_queue.length} messages');

    while (_queue.isNotEmpty) {
      final message = _queue.first;

      try {
        await _sendMessage(message);
        _queue.removeFirst();
        await _saveQueue();
        _logger.debug('Message synced successfully: ${message.id}');
      } catch (e) {
        _logger.error('Failed to sync message: ${message.id}', error: e);
        break; // Stop syncing on first error
      }
    }

    _isSyncing = false;
  }

  Future<void> _sendMessage(PendingMessage message) async {
    // Send message via ChatService
  }

  Future<void> _saveQueue() async {
    // Persist queue to SharedPreferences
  }

  Future<void> _loadQueue() async {
    // Load queue from SharedPreferences
  }
}

class PendingMessage {
  final String id;
  final String groupChatId;
  final String text;
  final String type;
  final DateTime timestamp;

  PendingMessage({
    required this.id,
    required this.groupChatId,
    required this.text,
    required this.type,
    required this.timestamp,
  });
}
```

**Integration with connectivity:**
```dart
// In main.dart or a connectivity service
Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none) {
    OfflineMessageQueue().sync();
  }
});
```

---

### 14. Comprehensive Error Handling with Retry Logic

**Implementation guide:**

```dart
// lib/utils/retry_helper.dart
class RetryHelper {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (e) {
        final shouldRetryError = shouldRetry?.call(e) ?? true;

        if (attempt >= maxAttempts || !shouldRetryError) {
          rethrow;
        }

        AppLogger.warning(
          'Operation failed, retrying (attempt $attempt/$maxAttempts)',
          {'error': e.toString(), 'delay': delay.inSeconds},
        );

        await Future.delayed(delay);
        delay *= backoffMultiplier;
      }
    }
  }
}

// Usage example:
final user = await RetryHelper.retry(
  operation: () => authService.signIn(email, password),
  maxAttempts: 3,
  shouldRetry: (error) => error is NetworkException,
);
```

---

## 📋 DEPLOYMENT CHECKLIST

Before deploying to production:

### Configuration
- [ ] Run `flutterfire configure` to generate real firebase_options.dart
- [ ] Set production PocketBase URL
- [ ] Enable Crashlytics and Analytics in Firebase Console
- [ ] Configure Firebase security rules
- [ ] Set up production PocketBase server with HTTPS
- [ ] Configure environment variables for production build

### Security
- [ ] Audit all SharedPreferences usage, migrate sensitive data to SecureStorage
- [ ] Review and update PocketBase security rules
- [ ] Enable CORS properly on PocketBase server
- [ ] Review all input validation
- [ ] Test rate limiting functionality
- [ ] Ensure all API keys are not hardcoded

### Testing
- [ ] Write unit tests for critical services
- [ ] Write widget tests for main screens
- [ ] Perform manual testing on physical devices
- [ ] Test offline functionality
- [ ] Test push notifications
- [ ] Load testing for high concurrent users

### Performance
- [ ] Run performance profiling
- [ ] Optimize image loading and caching
- [ ] Test with poor network conditions
- [ ] Check memory leaks
- [ ] Optimize database queries

### Compliance
- [ ] Add Privacy Policy
- [ ] Add Terms of Service
- [ ] Implement data deletion (GDPR compliance)
- [ ] Add age verification if required
- [ ] Review accessibility compliance

### Build
- [ ] Update version number in pubspec.yaml
- [ ] Create release notes
- [ ] Build signed APK/AAB for production
- [ ] Test release build thoroughly
- [ ] Prepare app store listings

---

## 🚀 BUILD COMMANDS REFERENCE

```bash
# Development
flutter run

# Staging
flutter build apk --release \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=POCKETBASE_URL=https://staging-api.educonnect.com

# Production
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=POCKETBASE_URL=https://api.educonnect.com

# Install dependencies
flutter pub get

# Run tests
flutter test --coverage

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

---

## 📚 ADDITIONAL RESOURCES

- [BUILD_CONFIG.md](BUILD_CONFIG.md) - Detailed build configuration guide
- [CLAUDE.md](CLAUDE.md) - Project overview and architecture
- [README.md](README.md) - Setup and installation guide

---

## ⚠️ IMPORTANT NOTES

1. **Firebase Setup:** You MUST run `flutterfire configure` before building - the current firebase_options.dart has placeholder values

2. **PocketBase URL:** Change from localhost before production deployment

3. **Rate Limiting:** Currently applied to auth only - implement for other operations

4. **Secure Storage:** Migration from SharedPreferences to SecureStorage for sensitive data is NOT yet done

5. **Tests:** Zero tests currently exist - this is a HIGH priority item

6. **Voice Recording:** Disabled but ready - just needs to be uncommented and tested

7. **File Upload:** Requires v2 embedding migration OR package replacement

8. **Quiz Feature:** Completely missing - significant work required

---

## 📞 SUPPORT

If you encounter issues during implementation:
1. Check logs using the new Logger system
2. Review Crashlytics for production errors
3. Ensure environment configuration is correct
4. Verify all dependencies are installed (`flutter pub get`)
5. Check Firebase Console for service status
