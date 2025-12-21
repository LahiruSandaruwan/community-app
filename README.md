# EduConnect - Educational Community Chat App

A Flutter-based mobile application designed for tutors to create and manage educational communities with real-time group chat functionality, similar to WhatsApp Communities.

## 🎯 Features

### Authentication
- Email/Password registration and login
- User roles: Tutor and Student
- Profile management with profile pictures
- Password reset functionality

### Community Management
- **Tutors can:**
  - Create communities (e.g., "Grade 11 Physics")
  - Generate and share invite codes (with QR codes)
  - Create multiple group chats within communities
  - Create announcement-only channels
  - Manage community members
  - Pin important messages
  - Delete communities

- **Students can:**
  - Join communities using invite codes
  - Participate in group discussions
  - View announcements
  - Read pinned messages

### Real-time Chat
- Group messaging with real-time updates
- Message timestamps and read receipts
- Typing indicators
- Message history
- Pin/unpin messages (Tutor only)
- Delete messages
- Announcement channels (Tutor-only posting)

### User Experience
- Clean Material Design UI
- Bottom navigation (Communities, Chats, Profile)
- Offline message caching
- Push notifications (FCM)
- Profile picture upload
- Responsive and intuitive interface

## 🛠️ Technical Stack

- **Framework:** Flutter 3.0+
- **State Management:** Provider
- **Backend Services:**
  - **PocketBase** - Self-hosted backend (Authentication, Database, File Storage)
  - Firebase Crashlytics & Analytics (Optional, for monitoring)
- **Architecture:** Clean Architecture with separation of concerns
  - Models
  - Services
  - Providers (State Management)
  - Screens (UI)
  - Widgets (Reusable components)
- **Database:** PocketBase with automated migrations and seeders
- **Infrastructure:** Environment-based configuration, structured logging, rate limiting

## 📋 Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK (for Android development)
- Xcode (for iOS development - optional)
- **PocketBase** (included in `pocketbase/` directory)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/LahiruSandaruwan/community-app.git
cd community-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. PocketBase Setup (Automated!)

#### Quick Start (Recommended)

```bash
# 1. Start PocketBase
cd pocketbase
./pocketbase serve

# 2. Create admin account (first-time only)
# Open browser: http://127.0.0.1:8090/_/
# Create admin (e.g., admin@local.com / password123)

# 3. Run automated migrations (creates all database schema)
./migrate.sh

# 4. Seed test data (optional - creates sample users & communities)
./seed.sh
```

**That's it!** Your database is fully configured with:
- ✅ All collections created (users, communities, messages, etc.)
- ✅ Custom user fields (role, phoneNumber, etc.)
- ✅ Sample test data (3 tutors, 8 students, 3 communities)

#### What Gets Created

**Test Users:**
- Tutors: `tutor1@educonnect.com` / `password123`
- Students: `student1@educonnect.com` / `password123`

**Test Communities:**
- Mathematics 101 (Code: `MATH101`)
- Physics Advanced (Code: `PHYS201`)
- Coding Bootcamp (Code: `CODE301`)

📖 **Detailed Guide:** See [DATABASE_MIGRATION_GUIDE.md](DATABASE_MIGRATION_GUIDE.md)

### 3. Firebase Setup (Optional - for Analytics/Crashlytics)

#### A. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "EduConnect")
4. Follow the setup wizard (disable Google Analytics for simpler setup)

#### B. Enable Firebase Services

1. **Authentication:**
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"

2. **Cloud Firestore:**
   - Go to Firestore Database
   - Click "Create database"
   - Start in **test mode** (change rules later)
   - Choose your region

3. **Storage:**
   - Go to Storage
   - Click "Get started"
   - Start in **test mode**

4. **Cloud Messaging:**
   - Already enabled by default

#### C. Configure Android App

1. In Firebase Console, click on Android icon
2. Register app with package name: `com.example.educonnect`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

#### D. Run FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will automatically:
- Generate `firebase_options.dart` with your Firebase configuration
- Set up platform-specific configurations

**OR manually update `lib/firebase_options.dart`** with your Firebase project details.

### 4. Update Firestore Security Rules

In Firebase Console > Firestore Database > Rules, use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Communities collection
    match /communities/{communityId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid in resource.data.adminIds;
    }

    // Group chats collection
    match /groupChats/{groupChatId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null;
      }

      // Typing indicators subcollection
      match /typing/{userId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### 5. Update Storage Security Rules

In Firebase Console > Storage > Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /chat_images/{groupChatId}/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 6. Run the App

```bash
# Check for issues
flutter doctor

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release
```

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart
│   ├── community_model.dart
│   ├── group_chat_model.dart
│   └── message_model.dart
├── services/                 # Business logic & Firebase
│   ├── auth_service.dart
│   ├── community_service.dart
│   ├── chat_service.dart
│   ├── storage_service.dart
│   └── notification_service.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── community_provider.dart
│   └── chat_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── registration_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── community/
│   │   ├── communities_screen.dart
│   │   ├── create_community_screen.dart
│   │   ├── join_community_screen.dart
│   │   ├── community_detail_screen.dart
│   │   └── create_group_screen.dart
│   ├── chat/
│   │   ├── chats_screen.dart
│   │   └── chat_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── home_screen.dart
├── widgets/                  # Reusable components
│   ├── message_bubble.dart
│   └── typing_indicator.dart
└── utils/                    # Constants & helpers
    ├── constants.dart
    └── theme.dart
```

## 🎨 User Flow

### For Tutors:
1. Sign up as a Tutor
2. Create a community (e.g., "Grade 11 Physics")
3. Get invite code (with QR code)
4. Share invite code with students
5. Create group chats within community
6. Create announcement channels
7. Send messages and announcements
8. Pin important messages
9. Manage members

### For Students:
1. Sign up as a Student
2. Receive invite code from tutor
3. Join community using code
4. Browse group chats
5. Participate in discussions
6. View announcements
7. Read pinned messages

## 📊 Firebase Usage Estimates (FREE Tier)

### Firestore (50K reads/day, 20K writes/day)
- **Reads:** Message loading, community lists, user profiles
- **Writes:** Send messages, create communities, update profiles
- **Estimate:** ~100-500 active users per day

### Storage (5GB, 1GB downloads/day)
- **Usage:** Profile pictures (~100KB each), chat images
- **Estimate:** ~5000 profile pictures or ~50GB of chat images

### Cloud Messaging (Unlimited)
- Push notifications for new messages
- No cost limitations

## 🔐 Security Best Practices

1. **Always use Firestore Security Rules** (see setup above)
2. **Storage Rules** to prevent unauthorized access
3. **Never commit** `google-services.json` or API keys to public repos
4. **Use environment variables** for sensitive data
5. **Implement rate limiting** for API calls
6. **Validate all user inputs** on both client and server

## 🚧 Future Enhancements

### Phase 2 (Planned)
- [ ] File sharing (documents, PDFs)
- [ ] Image sharing in chats
- [ ] Voice messages
- [ ] Video calls
- [ ] Homework assignments
- [ ] Quiz functionality
- [ ] Attendance tracking
- [ ] Analytics dashboard for tutors

### Phase 3 (Premium Features)
- [ ] Unlimited communities
- [ ] Priority support
- [ ] Custom branding
- [ ] Advanced analytics
- [ ] API access
- [ ] AdMob integration for free tier

## 🐛 Troubleshooting

### Common Issues

**1. Firebase not configured:**
```bash
# Solution: Run FlutterFire configuration
flutterfire configure
```

**2. Google Services error:**
- Ensure `google-services.json` is in `android/app/`
- Check package name matches Firebase console

**3. Build errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**4. Permission errors:**
- Check AndroidManifest.xml has required permissions
- Request runtime permissions for camera/storage

**5. Firestore permission denied:**
- Update Firestore security rules
- Ensure user is authenticated

## 📝 Environment Setup

### Android

**Minimum SDK:** 21 (Android 5.0)
**Target SDK:** 34 (Android 14)
**Permissions:** Internet, Camera, Storage

### iOS (Optional)

**Minimum iOS:** 12.0
**Permissions:** Camera, Photo Library

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Support

For issues and questions:
- Open an issue on GitHub
- Email: support@educonnect.example.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for backend services
- Material Design for UI guidelines

---

**Built with ❤️ for education**

*EduConnect - Connect. Learn. Grow.*
