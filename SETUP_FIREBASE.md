# 🔥 Firebase Setup Guide - CRITICAL

## ⚠️ CRITICAL ISSUE DETECTED

**Your app is missing `google-services.json`!**

This file is REQUIRED for Firebase to work. Without it, sign in/sign up will NEVER work.

---

## 📋 Step-by-Step Firebase Setup

### Step 1: Download google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **educonnect-149ad** (or create a new one)
3. Click the ⚙️ icon next to "Project Overview"
4. Select "Project settings"
5. Scroll down to "Your apps"
6. Find your Android app or click "Add app" if it doesn't exist
7. Download the `google-services.json` file
8. Place it in `android/app/google-services.json`

### Step 2: Verify the Configuration

```bash
# Check if the file exists
ls -la android/app/google-services.json

# It should show the file with ~2-5KB size
```

### Step 3: Enable Firebase Services

In Firebase Console, enable these services:

1. **Authentication**
   - Go to Build > Authentication
   - Click "Get Started"
   - Enable "Email/Password" sign-in method

2. **Cloud Firestore**
   - Go to Build > Firestore Database
   - Click "Create database"
   - Start in **production mode** (we'll add rules next)
   - Choose your region (closest to your users)

3. **Storage** (for profile pictures and resources)
   - Go to Build > Storage
   - Click "Get started"
   - Start in production mode

### Step 4: Set Up Firestore Security Rules

In Firestore Database > Rules, paste these rules:

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
      allow read: if request.auth != null &&
        request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        request.auth.uid in resource.data.adminIds;
      allow delete: if request.auth != null &&
        request.auth.uid in resource.data.adminIds;
    }

    // Group chats collection
    match /groupChats/{groupChatId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update: if request.auth != null;
        allow delete: if request.auth != null;
      }

      // Typing subcollection
      match /typing/{userId} {
        allow read, write: if request.auth != null;
      }
    }

    // Bookmarks collection
    match /bookmarks/{bookmarkId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }

    // Assignments collection
    match /assignments/{assignmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Polls collection
    match /polls/{pollId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // User stats (gamification) collection
    match /userStats/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.uid == userId;
    }

    // Attendance collection
    match /attendance/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Resources collection
    match /resources/{resourceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 5: Set Up Storage Security Rules

In Storage > Rules, paste these rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Profile pictures
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Community images
    match /community_images/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Chat images
    match /chat_images/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Voice messages
    match /voice_messages/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Resources
    match /resources/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Step 6: Rebuild the App

After adding `google-services.json`:

```bash
# Clean everything
flutter clean
rm -rf build/ android/build/ android/app/build/

# Rebuild
flutter pub get
flutter run
```

---

## 🧪 Test the Setup

1. Add this to your login screen temporarily:

```dart
import 'screens/auth/test_auth_screen.dart';

// Add a button:
TextButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TestAuthScreen()),
  ),
  child: const Text('Run Diagnostics'),
)
```

2. Run the app and click "Run Diagnostics"
3. It will test Firebase Auth and Firestore connectivity
4. All tests should pass ✅

---

## 📝 Quick Checklist

- [ ] `google-services.json` exists in `android/app/`
- [ ] Firebase Authentication is enabled (Email/Password)
- [ ] Cloud Firestore is created
- [ ] Firestore security rules are set
- [ ] Storage is set up with security rules
- [ ] App has been rebuilt: `flutter clean && flutter run`
- [ ] Test diagnostics pass

---

## 🆘 Still Not Working?

If you've done all the above and it still doesn't work:

1. **Check your Firebase project ID matches:**
   ```dart
   // In lib/firebase_options.dart
   projectId: 'educonnect-149ad'  // Should match your Firebase project
   ```

2. **Check your package name:**
   ```gradle
   // In android/app/build.gradle
   applicationId "com.example.educonnect"  // Should match Firebase console
   ```

3. **Run the diagnostics:**
   - Use the TestAuthScreen to see exactly what's failing

4. **Check Firebase Console:**
   - Go to Authentication > Users
   - Try to manually add a test user
   - If you can't, there's a Firebase project configuration issue

---

## 🎯 Expected Result

After proper setup, you should be able to:
- ✅ Sign up new users
- ✅ Sign in existing users
- ✅ See users in Firebase Console > Authentication
- ✅ See user documents in Firestore > users collection
