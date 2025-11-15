# 🔍 Sign-In Debugging Guide

## ⚠️ You cannot sign in? Follow these steps:

### Step 1: Use the Simple Login Test

I've created a minimal test screen to isolate the issue.

**Add this to your `login_screen.dart` temporarily:**

```dart
import 'screens/auth/simple_login_test.dart';

// Add below the "Sign Up" link at the bottom:
const SizedBox(height: 16),
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SimpleLoginTest()),
  ),
  icon: const Icon(Icons.bug_report),
  label: const Text('Debug Login'),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
)
```

Then:
1. Run the app
2. Click "Debug Login" button
3. Click each test button in order (1, 2, 3)
4. Watch the status messages
5. Take a screenshot and share what you see

---

### Step 2: Verify Firebase Configuration

Run these checks:

#### A. Check `google-services.json` exists
```bash
ls -la android/app/google-services.json
```
**Expected:** Should show a file (~2-5KB)
**If missing:** Download from Firebase Console

#### B. Check `firebase_options.dart`
```bash
cat lib/firebase_options.dart | grep projectId
```
**Expected:** Should show `projectId: 'educonnect-149ad'`
**If different:** Your Firebase project doesn't match

#### C. Verify Firebase Console settings

Go to [Firebase Console](https://console.firebase.google.com/):

1. **Authentication**
   - Go to Build > Authentication
   - Check if "Email/Password" is **ENABLED** (toggle should be ON)
   - Screenshot: Should show green checkmark

2. **Firestore Database**
   - Go to Build > Firestore Database
   - Check if database is **created**
   - Should show rules, data, indexes tabs
   - If you see "Create database" button, click it!

3. **Check the rules**
   - Click "Rules" tab
   - Should have rules allowing authenticated users to read/write
   - If it says `allow read, write: if false;` change it!

---

### Step 3: Common Issues & Fixes

#### Issue: "Operation not allowed"
**Cause:** Email/Password auth not enabled
**Fix:**
1. Go to Firebase Console > Authentication
2. Click "Sign-in method" tab
3. Click "Email/Password"
4. Enable it and Save

#### Issue: "Permission denied"
**Cause:** Firestore rules are too restrictive
**Fix:**
1. Go to Firebase Console > Firestore > Rules
2. Use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Issue: "Network request failed"
**Cause:** No internet or Firebase service down
**Fix:**
1. Check your internet connection
2. Try on different network (wifi/mobile data)
3. Check Firebase status: https://status.firebase.google.com/

#### Issue: "PigeonUserDetails type cast error"
**Cause:** Build cache corruption
**Fix:**
```bash
flutter clean
rm -rf build/ android/build/ android/app/build/
flutter pub get
# Uninstall app from device/emulator
flutter run
```

#### Issue: "User profile not found"
**Cause:** User exists in Auth but not in Firestore
**Fix:**
1. Go to Firebase Console > Authentication > Users
2. Delete the test user
3. Try signing up again (it will create Firestore document too)

---

### Step 4: Manual Verification

#### Test Firebase Auth directly:

1. Go to Firebase Console > Authentication > Users
2. Click "Add user"
3. Add email: `test@test.com`, password: `test123456`
4. Click "Add user"
5. Now try signing in with this user in your app

#### Test Firestore directly:

1. Go to Firebase Console > Firestore Database > Data
2. Click "Start collection"
3. Collection ID: `users`
4. Document ID: (use the UID from Authentication)
5. Add fields:
   - email (string): `test@test.com`
   - name (string): `Test User`
   - role (string): `student`
   - isOnline (boolean): `true`
   - communityIds (array): []
   - mutedGroupChatIds (array): []
6. Save
7. Try signing in now

---

### Step 5: Check Android Configuration

#### Verify package name matches:

```bash
grep applicationId android/app/build.gradle
```
**Expected:** `applicationId "com.example.educonnect"`

This MUST match the package name in Firebase Console:
1. Go to Firebase Console > Project Settings
2. Check "Your apps" section
3. Android package name should be: `com.example.educonnect`
4. If different, either:
   - Change in `build.gradle` to match Firebase, OR
   - Add a new app in Firebase Console with correct package

---

### Step 6: Enable Detailed Logging

Add this to see exactly what's happening:

**In `lib/services/auth_service.dart`, around line 68:**

```dart
Future<UserModel?> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    print('🔵 Starting sign in for: $email');

    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('🟢 Auth successful, UID: ${userCredential.user?.uid}');

    // Get user data from Firestore
    print('🔵 Fetching user document from Firestore...');
    DocumentSnapshot userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userCredential.user!.uid)
        .get();

    print('🟢 Document fetched, exists: ${userDoc.exists}');
    print('🟢 Document data: ${userDoc.data()}');

    // ... rest of code
```

Then check your console/logcat for these colored logs.

---

### Step 7: Last Resort - Start Fresh

If nothing works:

```bash
# 1. Delete everything
flutter clean
rm -rf build/ android/build/ android/app/build/ .dart_tool/
rm -f pubspec.lock

# 2. Uninstall app completely from device/emulator

# 3. Delete test users from Firebase Console > Authentication

# 4. Delete test documents from Firebase Console > Firestore

# 5. Rebuild from scratch
flutter pub get
flutter run --release

# 6. Try signing up (not signing in) with a NEW email
```

---

## 🆘 Still Stuck?

If you've tried everything above and it still doesn't work, provide me with:

1. **Screenshot of the Simple Login Test results** (all 3 tests)
2. **Screenshot of Firebase Console > Authentication > Sign-in method** (showing Email/Password enabled)
3. **Screenshot of Firebase Console > Firestore Database** (showing the database exists)
4. **The EXACT error message** you see in the app
5. **Output of:** `flutter doctor -v`
6. **Output of:** `grep projectId lib/firebase_options.dart`

With this information, I can identify the exact issue!
