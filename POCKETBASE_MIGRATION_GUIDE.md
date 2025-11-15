# PocketBase Migration Guide for EduConnect

This guide will help you migrate from Firebase to PocketBase for your EduConnect chat application.

## ✅ Setup Completed

1. **PocketBase Server Installed** - Located in `/pocketbase` directory
2. **Server Running** - http://127.0.0.1:8090
3. **Admin Dashboard** - http://127.0.0.1:8090/_/
4. **PocketBase Flutter Package Added** - v0.23.0

## 📋 Migration Steps

### Step 1: Set Up PocketBase Admin Account

1. Open http://127.0.0.1:8090/_/ in your browser
2. Create your first admin/superuser account
3. Access the admin dashboard

### Step 2: Create Database Schema

Create the following collections in PocketBase:

#### **users** Collection
- `email` (email, required, unique)
- `name` (text, required)
- `role` (select: tutor/student, required)
- `profilePictureUrl` (url)
- `phoneNumber` (text)
- `createdAt` (date, required)
- `lastSeen` (date)
- `isOnline` (bool, default: false)
- `fcmToken` (text)
- `communityIds` (json, default: [])
- `mutedGroupChatIds` (json, default: [])

#### **communities** Collection
- `name` (text, required)
- `description` (text)
- `createdBy` (relation: users)
- `communityImageUrl` (url)
- `inviteCode` (text, unique, required)
- `isActive` (bool, default: true)
- `memberIds` (json, default: [])
- `adminIds` (json, default: [])
- `groupChatIds` (json, default: [])
- `createdAt` (date, required)

#### **groupChats** Collection
- `name` (text, required)
- `communityId` (relation: communities, required)
- `createdBy` (relation: users)
- `isAnnouncementOnly` (bool, default: false)
- `memberIds` (json, default: [])
- `lastMessage` (text)
- `lastMessageTime` (date)
- `createdAt` (date, required)

#### **messages** Collection
- `groupChatId` (relation: groupChats, required)
- `senderId` (relation: users, required)
- `senderName` (text, required)
- `text` (text)
- `type` (select: text/image/voice/announcement/poll/quiz/assignment, default: text)
- `imageUrl` (url)
- `isPinned` (bool, default: false)
- `readBy` (json, default: [])
- `timestamp` (date, required)

### Step 3: Configure Real-time Subscriptions

PocketBase supports real-time subscriptions out of the box!

```dart
// Subscribe to messages in a group chat
pb.collection('messages').subscribe('*', (e) {
  if (e.record!['groupChatId'] == currentGroupChatId) {
    // Handle new message
  }
});
```

### Step 4: Migrate Services

#### Create PocketBase Service (`lib/services/pocketbase_service.dart`)

```dart
import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBase pb = PocketBase('http://127.0.0.1:8090');

  static bool get isAuthenticated => pb.authStore.isValid;
  static String? get currentUserId => pb.authStore.record?.id;
}
```

#### Update AuthService

Replace Firebase Auth methods with PocketBase:

```dart
// Sign up
final record = await pb.collection('users').create(body: {
  'email': email,
  'password': password,
  'passwordConfirm': password,
  'name': name,
  'role': role,
  'emailVisibility': true,
});

// Authenticate
await pb.collection('users').authWithPassword(email, password);
```

### Step 5: Update Providers

Modify your providers to use PocketBase instead of Firebase:

```dart
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

class AuthProvider with ChangeNotifier {
  final PocketBase _pb = PocketBaseService.pb;

  Future<bool> signIn(String email, String password) async {
    try {
      await _pb.collection('users').authWithPassword(email, password);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### Step 6: Remove Firebase Dependencies

After migration is complete:

1. Remove Firebase packages from pubspec.yaml
2. Delete `lib/firebase_options.dart`
3. Remove Firebase initialization from `main.dart`
4. Remove `google-services.json` from `android/app/`
5. Clean up Firebase-related code

## 🔥 Key Differences: Firebase vs PocketBase

| Feature | Firebase | PocketBase |
|---------|----------|------------|
| **Authentication** | `FirebaseAuth.instance.signInWithEmailAndPassword()` | `pb.collection('users').authWithPassword()` |
| **Database** | NoSQL (Firestore) | SQLite (relational) |
| **Real-time** | `snapshots()` | `subscribe()` |
| **Storage** | Firebase Storage | Built-in file uploads |
| **Queries** | Limited to Firestore queries | Full SQL power |
| **Offline** | Built-in | Manual implementation |
| **Cost** | Pay-per-use | Free (self-hosted) |

## 💰 Cost Comparison

### Firebase (Current)
- Firestore: 50K reads/day free, then $0.06 per 100K reads
- Authentication: Free
- Storage: 5GB free, then $0.026/GB
- **Unpredictable costs** as you scale

### PocketBase (New)
- **100% Free** if self-hosted
- Hosting costs: $5-10/month (DigitalOcean, Hetzner, etc.)
- **Predictable** monthly cost

## 🚀 Deployment Options

### Option 1: Free Hosting (Railway.app)
1. Create account on Railway.app
2. Deploy PocketBase using Docker
3. Free $5/month credit (enough for small apps)

### Option 2: Low-Cost VPS ($5/month)
1. Get a DigitalOcean/Hetzner VPS
2. Install Docker
3. Run PocketBase container
4. Set up reverse proxy (Nginx/Caddy)

### Option 3: Fly.io (Free Tier)
1. Deploy to Fly.io free tier
2. 3GB persistent storage included
3. Free SSL certificates

## 📝 Next Steps

1. **Test Locally First** - Ensure everything works with local PocketBase
2. **Migrate Gradually** - Start with authentication, then move to other features
3. **Keep Firebase** - Don't delete Firebase until fully migrated and tested
4. **Deploy PocketBase** - Once tested, deploy to production hosting

## 🔧 Useful PocketBase Commands

```bash
# Start server
./pocketbase serve

# Create admin
./pocketbase superuser upsert admin@example.com mypassword

# Export database
./pocketbase export

# Import database
./pocketbase import backup.zip
```

## 📚 Resources

- [PocketBase Documentation](https://pocketbase.io/docs/)
- [PocketBase Dart/Flutter SDK](https://github.com/pocketbase/dart-sdk)
- [PocketBase Discord Community](https://discord.gg/pocketbase)

## ⚠️ Important Notes

1. **Backup Your Data** - Always backup Firebase data before migration
2. **Test Thoroughly** - Test all features before going live
3. **Real-time Subscriptions** - PocketBase real-time is different from Firestore
4. **File Storage** - PocketBase has built-in file storage, simpler than Firebase Storage
5. **Security Rules** - PocketBase uses collection-level rules (simpler than Firestore)

---

**Current Status:**
- ✅ PocketBase server running locally
- ✅ Flutter package installed
- ⏳ Schema setup needed
- ⏳ Service layer migration needed
- ⏳ Testing needed
