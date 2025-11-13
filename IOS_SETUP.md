# iOS Setup Guide

This guide will help you set up the EduConnect app for iOS devices.

## Prerequisites

- macOS computer (required for iOS development)
- Xcode 14.0 or later
- CocoaPods installed
- Apple Developer account (for testing on physical devices)

## Step 1: Install Xcode

1. Install Xcode from the Mac App Store
2. Open Xcode and accept the license agreement
3. Install additional required components

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

## Step 2: Install CocoaPods

```bash
sudo gem install cocoapods
```

## Step 3: Configure Firebase for iOS

### Option A: Using FlutterFire CLI (Recommended)

```bash
# This will configure iOS automatically
flutterfire configure --platforms=ios
```

### Option B: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the iOS icon (or Add app if not already added)
4. **Bundle ID:** `com.example.educonnect` (or your custom bundle ID)
5. **App nickname:** EduConnect iOS
6. Download `GoogleService-Info.plist`
7. Place it in: `ios/Runner/GoogleService-Info.plist`

**IMPORTANT:** The `GoogleService-Info.plist` file should be placed directly in the `ios/Runner/` directory.

## Step 4: Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

This will install all required iOS dependencies including Firebase.

## Step 5: Open in Xcode

```bash
open ios/Runner.xcworkspace
```

**Note:** Always open the `.xcworkspace` file, NOT the `.xcodeproj` file!

## Step 6: Configure Bundle Identifier

In Xcode:
1. Click on **Runner** in the left sidebar
2. Select **Runner** target
3. Go to **General** tab
4. Update **Bundle Identifier** (e.g., `com.example.educonnect`)
5. Select your **Team** (requires Apple Developer account)

## Step 7: Enable Push Notifications

In Xcode:
1. Select **Runner** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Push Notifications**
5. Add **Background Modes**
6. Check **Remote notifications** under Background Modes

## Step 8: Configure App Permissions

The `Info.plist` is already configured with necessary permissions:
- **Camera:** For profile pictures and image sharing
- **Photo Library:** For selecting images
- **Microphone:** For future voice messages

You can customize the permission messages in `ios/Runner/Info.plist`.

## Step 9: Build and Run

### On Simulator:

```bash
flutter run -d "iPhone 14"
```

Or in Xcode:
1. Select a simulator from the device dropdown
2. Click the Run button (▶️)

### On Physical Device:

```bash
# List connected devices
flutter devices

# Run on connected iPhone
flutter run -d <device-id>
```

Or in Xcode:
1. Connect your iPhone via USB
2. Select your device from the dropdown
3. Click Run (▶️)
4. Trust the developer certificate on your iPhone (Settings → General → Device Management)

## Step 10: Enable APNs for Push Notifications

For push notifications to work on iOS, you need to configure APNs (Apple Push Notification service):

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create an **APNs Certificate** or **APNs Key**
4. Upload to Firebase Console:
   - Go to Project Settings → Cloud Messaging
   - Under iOS app configuration, upload APNs certificate/key

## Troubleshooting

### Error: "No such module 'Firebase'"

**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Error: "Code signing required"

**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your Team in Signing & Capabilities
3. Or use automatic code signing

### Error: "GoogleService-Info.plist not found"

**Solution:**
- Make sure the file is in `ios/Runner/GoogleService-Info.plist`
- Not in `ios/` or any other location

### Build fails with pod errors

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Simulator not working

**Solution:**
```bash
# List available simulators
xcrun simctl list devices

# Reset simulator
xcrun simctl erase all

# Restart Xcode
```

## Testing on iOS

### Things to Test:

1. ✅ Login and registration
2. ✅ Create community (tutors)
3. ✅ Join community (students)
4. ✅ Send and receive messages
5. ✅ Upload profile picture
6. ✅ Push notifications
7. ✅ Typing indicators
8. ✅ Read receipts
9. ✅ Pin messages (tutors)
10. ✅ Group info screen

### Push Notification Testing:

**Important:** Push notifications don't work on iOS Simulator! You MUST test on a physical device.

1. Build and run on a physical iPhone
2. Grant notification permissions when prompted
3. Background the app
4. Send a message from another device
5. You should receive a push notification

## App Store Preparation

When ready to publish to the App Store:

1. **Update App Info:**
   - Change bundle ID in `ios/Runner.xcodeproj`
   - Update app name, version in `Info.plist`

2. **App Icons:**
   - Add app icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Use [App Icon Generator](https://appicon.co/) for all sizes

3. **Launch Screen:**
   - Customize `ios/Runner/Base.lproj/LaunchScreen.storyboard`

4. **Build Archive:**
   ```bash
   flutter build ipa --release
   ```

5. **Upload to App Store Connect:**
   - Open Xcode → Window → Organizer
   - Select the archive → Upload to App Store

## Minimum Requirements

- **iOS Version:** 12.0+
- **Xcode:** 14.0+
- **macOS:** 12.0+ (Monterey)
- **CocoaPods:** 1.11.0+

## Performance Tips

1. **Use Release Mode:**
   ```bash
   flutter run --release
   ```

2. **Profile Your App:**
   ```bash
   flutter run --profile
   ```

3. **Reduce App Size:**
   ```bash
   flutter build ipa --split-per-abi
   ```

## Additional Resources

- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

---

**That's it!** Your app is now configured for iOS! 🎉

Need help? Check the troubleshooting section or reach out to the community.
