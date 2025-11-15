# Fix Sign-In Error: PigeonUserDetails Type Cast Error

If you're experiencing the error:
```
An error occurred during sign in: type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?' in type cast
```

This is a Firebase Auth internal error caused by corrupted build cache and/or missing Firestore fields.

## Solution 1: Complete Clean Rebuild (Recommended)

Run the automated clean rebuild script:

```bash
chmod +x clean_rebuild.sh
./clean_rebuild.sh
```

Or manually:

```bash
# 1. Clean everything
flutter clean
rm -rf build/ android/build/ android/app/build/ .dart_tool/
rm -f pubspec.lock

# 2. Clean Android Gradle
cd android && ./gradlew clean && cd ..

# 3. Reinstall dependencies
flutter pub get

# 4. IMPORTANT: Uninstall the app from your device/emulator
#    This clears the app's cached data

# 5. Rebuild and run
flutter run --release
```

## Solution 2: Fix Firestore Data (If you have existing users)

If you have existing users in Firestore that were created before the `mutedGroupChatIds` field was added:

### Option A: Run Migration from App (Easiest)

1. Add the migration screen to your app temporarily:

```dart
// In your main.dart or home_screen.dart
import 'screens/admin/migration_screen.dart';

// Add a button or route to access it:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const MigrationScreen()),
);
```

2. Open the app and navigate to the Migration Screen
3. Click "Run Migrations"
4. Follow the on-screen instructions
5. Close app completely
6. Run: `flutter clean && flutter run`

### Option B: Manual Firestore Update

Go to Firebase Console > Firestore Database and manually add:
- Field: `mutedGroupChatIds`
- Type: Array
- Value: [] (empty array)

Do this for all existing user documents.

### Option C: Run Migration Script Directly

```dart
// Add this temporarily to your main.dart or splash screen:
import 'utils/firestore_migration.dart';

// In your initState or initialization code:
await FirestoreMigration.runAllMigrations();
```

## Solution 3: Start Fresh (Last Resort)

If nothing else works:

1. Delete the app from your device/emulator
2. Delete all users from Firebase Console > Authentication
3. Delete all documents from Firebase Console > Firestore
4. Run: `flutter clean && flutter pub get && flutter run`
5. Sign up as a new user

## Why This Error Happens

The error occurs because:
1. **Build Cache Issue**: Flutter's build cache or Firebase Auth's native cache is corrupted
2. **Schema Change**: The `mutedGroupChatIds` field was added to UserModel, but existing Firestore users don't have this field
3. **Platform Channel Mismatch**: Firebase Auth's platform channel (PigeonUserDetails) is out of sync

## Prevention

To prevent this in the future:
- Always run `flutter clean` after major dependency updates
- Always uninstall the app before testing after schema changes
- Run Firestore migrations when adding new required fields
- Use default values for new fields (already done in this project)

## Still Having Issues?

If the error persists after trying all solutions:

1. Check your Firebase project configuration in `lib/firebase_options.dart`
2. Make sure `google-services.json` is in `android/app/`
3. Verify Firebase Authentication is enabled in Firebase Console
4. Check that Firestore rules allow user document access
5. Try on a different device/emulator to rule out device-specific issues

## Need Help?

Create an issue with:
- Full error message
- Flutter version (`flutter --version`)
- Steps you've tried
- Output of `flutter doctor -v`
