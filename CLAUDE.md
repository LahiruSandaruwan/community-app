# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EduConnect is a Flutter-based educational community chat application designed for tutors to create and manage learning communities with real-time group chat functionality, similar to WhatsApp Communities. The app uses Firebase as its backend (Authentication, Firestore, Storage, Cloud Messaging).

**Package Name:** `com.example.educonnect`
**Current Flutter Version:** 3.38.0
**Dart Version:** 3.10.0

## Development Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Clean build artifacts and reinstall dependencies
flutter clean && flutter pub get

# Verify Flutter installation and dependencies
flutter doctor
```

### Running the App
```bash
# Run on connected device/emulator (debug mode)
flutter run

# Run with hot reload enabled (default)
flutter run --hot

# Run in release mode
flutter run --release

# Run on a specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Building
```bash
# Build Android APK (release)
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build for debug (with debug symbols)
flutter build apk --debug
```

### Testing & Analysis
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format all Dart files
flutter format lib/
```

### Firebase Configuration
```bash
# Install FlutterFire CLI (one-time setup)
dart pub global activate flutterfire_cli

# Configure Firebase for the project
flutterfire configure
```

## Architecture Overview

### State Management Pattern

The app uses **Provider** for state management with a clear separation of concerns:

1. **Models** (`lib/models/`) - Immutable data classes with Firestore serialization
   - Include `fromFirestore()` factory constructors
   - Include `toFirestore()` methods for serialization
   - Include `copyWith()` methods for immutability
   - Key models: `UserModel`, `CommunityModel`, `GroupChatModel`, `MessageModel`

2. **Services** (`lib/services/`) - Business logic and Firebase operations
   - Direct interaction with Firebase Auth, Firestore, Storage, FCM
   - Return Future or Stream for async operations
   - No UI dependencies
   - Key services: `AuthService`, `CommunityService`, `ChatService`, `StorageService`, `NotificationService`

3. **Providers** (`lib/providers/`) - State management with ChangeNotifier
   - Wrap services and expose state to UI
   - Handle loading states and error messages
   - Use `notifyListeners()` after state changes
   - Registered globally in `main.dart` using `MultiProvider`
   - Key providers: `AuthProvider`, `CommunityProvider`, `ChatProvider`, `ThemeProvider`, `BookmarkProvider`, `AssignmentProvider`, `PollProvider`, `GamificationProvider`, `AttendanceProvider`

4. **Screens** (`lib/screens/`) - UI components organized by feature
   - Consume providers using `Consumer` or `Provider.of<T>(context)`
   - Feature-based organization: auth, community, chat, profile, assignments, polls, gamification, attendance, resources
   - Bottom navigation structure in `home_screen.dart`

5. **Widgets** (`lib/widgets/`) - Reusable UI components
   - `message_bubble.dart` - Chat message display with different types
   - `typing_indicator.dart` - Real-time typing indicators
   - `voice_message_widget.dart` - Voice message playback
   - `poll_widget.dart` - Interactive poll display
   - `math_text_widget.dart` - Math equation rendering
   - `offline_indicator.dart` - Network status display

### Firebase Collections Structure

```
users/
  {userId}
    - email, name, role, profilePictureUrl, phoneNumber
    - createdAt, lastSeen, isOnline, fcmToken
    - communityIds[]

communities/
  {communityId}
    - name, description, createdBy, createdAt
    - communityImageUrl, inviteCode, isActive
    - memberIds[], adminIds[], groupChatIds[]

groupChats/
  {groupChatId}
    - name, communityId, createdBy, createdAt
    - isAnnouncementOnly, memberIds[]
    - lastMessage, lastMessageTime

    messages/ (subcollection)
      {messageId}
        - senderId, senderName, text, timestamp
        - type (text/image/voice/announcement/poll/quiz/assignment)
        - imageUrl, isPinned, readBy[]

    typing/ (subcollection)
      {userId}
        - isTyping, timestamp
```

### User Roles & Permissions

- **Tutor** (`role: 'tutor'`)
  - Create communities and generate invite codes
  - Create/manage group chats within communities
  - Create announcement-only channels
  - Pin/unpin messages
  - Delete communities and groups
  - Post in announcement channels

- **Student** (`role: 'student'`)
  - Join communities using invite codes
  - Participate in group chats
  - View announcements (read-only in announcement channels)
  - Read pinned messages

### Constants & Configuration

All app-wide constants are centralized in `lib/utils/constants.dart`:
- Collection names (`AppConstants.usersCollection`, etc.)
- User roles (`AppConstants.roleTutor`, `AppConstants.roleStudent`)
- Message types (`messageTypeText`, `messageTypeImage`, `messageTypeVoice`, etc.)
- Storage paths, SharedPreferences keys
- Limits (message length, file sizes, pagination)
- Standard error/success messages

Use these constants instead of hardcoding strings.

### Theme System

The app supports light/dark mode with theme switching:
- Theme definitions in `lib/utils/theme.dart` (`AppTheme.lightTheme`, `AppTheme.darkTheme`)
- Theme state managed by `ThemeProvider`
- Theme mode accessible via `Consumer<ThemeProvider>`
- Persisted using SharedPreferences

## Firebase Setup Requirements

**Critical:** Before running the app, ensure Firebase is properly configured:

1. Place `google-services.json` in `android/app/`
2. Run `flutterfire configure` to generate `lib/firebase_options.dart`
3. Verify Firebase services are enabled in Firebase Console:
   - Authentication (Email/Password)
   - Cloud Firestore (with security rules applied)
   - Storage (with security rules applied)
   - Cloud Messaging

### Security Rules

The app requires specific Firestore security rules (see README.md for full rules):
- Users can only write to their own user document
- Community updates restricted to admins
- Messages accessible to authenticated users
- File uploads restricted by user ID

## Message Types & Features

The chat system supports multiple message types:

- **Text messages** - Standard text with markdown support
- **Image messages** - Photos from camera/gallery
- **Voice messages** - Audio recordings with playback
- **Announcements** - Tutor-only messages in announcement channels
- **Polls** - Interactive voting with real-time results
- **Assignments** - Homework with due dates and submissions
- **Quiz** - Assessment messages (planned feature)

Message features:
- Real-time delivery via Firestore listeners
- Read receipts (readBy array)
- Typing indicators (subcollection with cleanup)
- Message pinning (tutor only)
- Offline message caching (SharedPreferences)

## Advanced Features

The app includes several advanced educational features:

1. **Bookmarks/Saved Messages** - Save important messages for later
2. **Assignments System** - Create, submit, and grade assignments
3. **Polls** - Create and vote in polls with real-time results
4. **Gamification** - Points, achievements, leaderboards for engagement
5. **Attendance Tracking** - Check-in system for tutors
6. **Resource Library** - Share documents, links, and learning materials
7. **Voice Messages** - Record and playback audio messages
8. **Math Equations** - Render LaTeX-style math formulas
9. **Dark Mode** - System-wide theme switching

## Android Configuration

**Minimum SDK:** 21 (Android 5.0)
**Target SDK:** 34 (Android 14)
**Compile SDK:** 36
**MultiDex:** Enabled (required for Firebase)

The app uses Firebase BOM version 32.7.0 for dependency management.

## Common Development Patterns

### Adding a New Feature

1. **Create Model** (if needed) in `lib/models/`
   - Add Firestore serialization methods
   - Include `copyWith()` for immutability

2. **Create Service** in `lib/services/`
   - Handle all Firebase operations
   - Return Future/Stream as appropriate
   - Use constants from `AppConstants`

3. **Create/Update Provider** in `lib/providers/`
   - Wrap service with ChangeNotifier
   - Expose loading/error states
   - Register in `main.dart` MultiProvider

4. **Create UI** in `lib/screens/` or `lib/widgets/`
   - Use Consumer or Provider.of to access state
   - Handle loading and error states in UI

### Working with Firestore

Always use streaming for real-time updates:
```dart
Stream<QuerySnapshot> stream = _firestore
  .collection(AppConstants.groupChatsCollection)
  .doc(groupChatId)
  .collection(AppConstants.messagesCollection)
  .orderBy('timestamp', descending: true)
  .limit(AppConstants.messagesPerPage)
  .snapshots();
```

Use batch writes for related operations:
```dart
WriteBatch batch = _firestore.batch();
batch.update(communityRef, {'memberIds': FieldValue.arrayUnion([userId])});
batch.update(userRef, {'communityIds': FieldValue.arrayUnion([communityId])});
await batch.commit();
```

### Error Handling

- Wrap Firebase operations in try-catch blocks
- Use constants from `AppConstants` for error messages
- Display errors using `Fluttertoast` or `ScaffoldMessenger`
- Set loading states appropriately in providers

## Known Issues & Compatibility

- Some packages temporarily disabled due to v1 embedding issues:
  - `file_picker` - File selection
  - `syncfusion_flutter_pdfviewer` - PDF viewing
- Linux platform audio recording requires dependency overrides (see pubspec.yaml)
- Minimum Android SDK 21 required for Firebase compatibility

## Firebase Free Tier Limits

Be aware of Firebase free tier quotas:
- **Firestore:** 50K reads/day, 20K writes/day, 1GB storage
- **Storage:** 5GB storage, 1GB downloads/day
- **Cloud Messaging:** Unlimited (free)

Optimize read operations:
- Use pagination (`limit()` queries)
- Cache data locally when possible
- Use Firestore listeners efficiently (unsubscribe when not needed)
