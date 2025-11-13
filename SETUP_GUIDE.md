# EduConnect - Quick Setup Guide

## ⚡ Quick Start (5 Minutes)

### Step 1: Install Flutter
```bash
# Check if Flutter is installed
flutter --version

# If not installed, download from: https://flutter.dev/docs/get-started/install
```

### Step 2: Get Dependencies
```bash
cd community-app
flutter pub get
```

### Step 3: Firebase Setup

#### Option A: Using FlutterFire CLI (Recommended - Fastest)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase automatically
flutterfire configure

# This will:
# - Create a Firebase project (or select existing)
# - Register your app
# - Generate firebase_options.dart
# - Download google-services.json
```

#### Option B: Manual Setup (15 minutes)

1. **Create Firebase Project:**
   - Go to https://console.firebase.google.com/
   - Click "Add project"
   - Name it "EduConnect" (or your choice)
   - Disable Google Analytics (optional)
   - Click "Create project"

2. **Enable Authentication:**
   - In Firebase Console, click "Authentication"
   - Click "Get started"
   - Enable "Email/Password"

3. **Create Firestore Database:**
   - Click "Firestore Database"
   - Click "Create database"
   - Choose "Start in test mode"
   - Select your region
   - Click "Enable"

4. **Enable Storage:**
   - Click "Storage"
   - Click "Get started"
   - Keep default rules
   - Click "Done"

5. **Add Android App:**
   - Click the Android icon on project overview
   - Package name: `com.example.educonnect`
   - App nickname: "EduConnect"
   - Click "Register app"
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`
   - Click "Next" through remaining steps

6. **Update Firebase Options:**
   - Open `lib/firebase_options.dart`
   - Replace placeholder values with your Firebase config values from the Firebase Console

### Step 4: Run the App
```bash
# Check devices
flutter devices

# Run on connected device
flutter run

# Or run in release mode
flutter run --release
```

## 🔧 Configuration Checklist

### Before First Run:
- [ ] Flutter installed and working (`flutter doctor`)
- [ ] Firebase project created
- [ ] `google-services.json` in `android/app/`
- [ ] `firebase_options.dart` updated with your config
- [ ] Dependencies installed (`flutter pub get`)

### Firebase Services Enabled:
- [ ] Authentication (Email/Password)
- [ ] Cloud Firestore
- [ ] Storage
- [ ] Cloud Messaging (enabled by default)

## 📱 Testing the App

### Test as Tutor:
1. Launch app
2. Click "Sign Up"
3. Fill in details and select "Tutor"
4. Create a community
5. View the invite code (QR code displayed)
6. Create a group chat
7. Send messages

### Test as Student:
1. Launch app (different device/account)
2. Click "Sign Up"
3. Fill in details and select "Student"
4. Click "Join Community" on Communities screen
5. Enter the invite code from tutor
6. Browse and join group chats
7. Send messages

## 🐛 Common Issues & Fixes

### Issue: Firebase not configured
```
Error: No Firebase App '[DEFAULT]' has been created
```
**Fix:** Run `flutterfire configure` or check `firebase_options.dart`

### Issue: Google Services error
```
Error: File google-services.json is missing
```
**Fix:**
1. Download from Firebase Console
2. Place in `android/app/google-services.json`

### Issue: Build fails
```bash
# Clean and rebuild
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### Issue: Permission denied in Firestore
**Fix:** Update Firestore Security Rules in Firebase Console:
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

## 🎯 Next Steps

1. **Customize the App:**
   - Update app name in `pubspec.yaml`
   - Change package name if needed
   - Add custom app icon
   - Modify color scheme in `lib/utils/theme.dart`

2. **Deploy to Production:**
   - Update Firestore rules (see README.md)
   - Update Storage rules
   - Set up Cloud Functions for notifications
   - Build release APK: `flutter build apk --release`

3. **Add Features:**
   - Implement file sharing
   - Add image messages
   - Create homework assignments
   - Build analytics dashboard

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

## 💡 Tips

- Use **test mode** for Firestore rules during development
- Set up **proper security rules** before production
- Monitor **Firebase usage** in Firebase Console
- Stay within **free tier limits** (see README.md)
- Test on **real devices** for best experience

## 🆘 Need Help?

- Check the full [README.md](README.md)
- Review [Troubleshooting section](README.md#troubleshooting)
- Open an issue on GitHub
- Check Flutter/Firebase documentation

---

**That's it! You're ready to go! 🚀**
