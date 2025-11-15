# PocketBase Migration Status

## ✅ Completed Migrations

### 1. Core Infrastructure
- ✅ Created `lib/services/pocketbase_service.dart` - Base PocketBase client singleton
- ✅ Created `lib/services/pocketbase_auth_service.dart` - Complete authentication service
- ✅ Updated `lib/models/user_model.dart` - Added `fromPocketBase()` and `toPocketBase()` methods
- ✅ Updated `lib/providers/auth_provider.dart` - Now uses `PocketBaseAuthService`
- ✅ Updated `lib/main.dart` - Removed Firebase initialization
- ✅ Removed Firebase packages from `pubspec.yaml`

## ⏳ In Progress / Pending

### 2. Models to Migrate (Replace Firestore with PocketBase)

All models need to:
1. Change `import 'package:cloud_firestore/cloud_firestore.dart';` to `import 'package:pocketbase/pocketbase.dart';`
2. Replace `fromFirestore(DocumentSnapshot doc)` with `fromPocketBase(RecordModel record)`
3. Replace `toFirestore()` with `toPocketBase()`
4. Replace `Timestamp` with `DateTime` (use `.toIso8601String()` and `DateTime.parse()`)

**Files to update:**
- `lib/models/assignment_model.dart`
- `lib/models/attendance_model.dart`
- `lib/models/bookmark_model.dart`
- `lib/models/community_model.dart`
- `lib/models/group_chat_model.dart`
- `lib/models/message_model.dart`
- `lib/models/poll_model.dart`
- `lib/models/resource_model.dart`
- `lib/models/user_stats_model.dart`

### 3. Services to Migrate

**Critical services (needed for basic app functionality):**
- `lib/services/community_service.dart` - Community management
- `lib/services/chat_service.dart` - Chat functionality
- `lib/services/storage_service.dart` - File uploads

**Secondary services:**
- `lib/services/assignment_service.dart`
- `lib/services/attendance_service.dart`
- `lib/services/bookmark_service.dart`
- `lib/services/gamification_service.dart`
- `lib/services/poll_service.dart`
- `lib/services/resource_service.dart`
- `lib/services/notification_service.dart` - May need FCM alternative or disable
- `lib/services/voice_message_service.dart`

### 4. Test/Utility Files (Can be removed or updated later)
- `lib/screens/auth/simple_login_test.dart` - Test file
- `lib/screens/auth/test_auth_screen.dart` - Test file
- `lib/utils/firestore_migration.dart` - Firebase migration utility (no longer needed)
- `lib/firebase_options.dart` - Firebase config (can be deleted)

### 5. Screens Using Firebase Directly
- `lib/screens/chat/group_info_screen.dart`
- `lib/screens/chat/search_messages_screen.dart`
- `lib/screens/community/member_management_screen.dart`

## Migration Pattern Reference

### Firestore → PocketBase Cheat Sheet

#### Model Updates

**Before (Firestore):**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MyModel {
  factory MyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MyModel(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // ...
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      // ...
    };
  }
}
```

**After (PocketBase):**
```dart
import 'package:pocketbase/pocketbase.dart';

class MyModel {
  factory MyModel.fromPocketBase(RecordModel record) {
    return MyModel(
      id: record.id,
      createdAt: DateTime.parse(record.getStringValue('createdAt', DateTime.now().toIso8601String())),
      // ...
    );
  }

  Map<String, dynamic> toPocketBase() {
    return {
      'createdAt': createdAt.toIso8601String(),
      // ...
    };
  }
}
```

#### Service Updates

**Before (Firestore):**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createItem(MyModel item) async {
    await _firestore.collection('items').doc(item.id).set(item.toFirestore());
  }

  Future<MyModel?> getItem(String id) async {
    DocumentSnapshot doc = await _firestore.collection('items').doc(id).get();
    if (!doc.exists) return null;
    return MyModel.fromFirestore(doc);
  }

  Stream<List<MyModel>> streamItems() {
    return _firestore.collection('items').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MyModel.fromFirestore(doc)).toList();
    });
  }
}
```

**After (PocketBase):**
```dart
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

class MyService {
  final PocketBase _pb = PocketBaseService().client;

  Future<void> createItem(MyModel item) async {
    await _pb.collection('items').create(body: item.toPocketBase());
  }

  Future<MyModel?> getItem(String id) async {
    try {
      RecordModel record = await _pb.collection('items').getOne(id);
      return MyModel.fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // PocketBase real-time subscriptions
  Stream<List<MyModel>> streamItems() async* {
    // Initial fetch
    final records = await _pb.collection('items').getFullList();
    yield records.map((r) => MyModel.fromPocketBase(r)).toList();

    // Subscribe to real-time updates
    _pb.collection('items').subscribe('*', (e) async {
      // Re-fetch on any change (or handle e.action for create/update/delete)
      final updated = await _pb.collection('items').getFullList();
      yield updated.map((r) => MyModel.fromPocketBase(r)).toList();
    });
  }
}
```

#### Key Differences

| Firestore | PocketBase |
|-----------|------------|
| `FirebaseFirestore.instance` | `PocketBaseService().client` |
| `.collection('items').doc(id).set(data)` | `.collection('items').create(body: data)` |
| `.collection('items').doc(id).update(data)` | `.collection('items').update(id, body: data)` |
| `.collection('items').doc(id).get()` | `.collection('items').getOne(id)` |
| `.collection('items').get()` | `.collection('items').getFullList()` |
| `.collection('items').snapshots()` | `.collection('items').subscribe('*', callback)` |
| `Timestamp.fromDate(date)` | `date.toIso8601String()` |
| `(timestamp as Timestamp).toDate()` | `DateTime.parse(string)` |
| `FieldValue.arrayUnion([item])` | Manual: fetch list, add item, update |
| `FieldValue.arrayRemove([item])` | Manual: fetch list, remove item, update |
| `FieldValue.serverTimestamp()` | `DateTime.now().toIso8601String()` |

## Next Steps

### Priority 1: Get Authentication Working
1. ✅ Auth service migrated
2. ✅ User model migrated
3. ✅ Auth provider updated
4. Run PocketBase: `cd pocketbase && ./pocketbase serve`
5. Create admin account and run `./init_collections.sh`
6. Test sign up/sign in flow

### Priority 2: Core App Functionality
1. Migrate `community_model.dart`, `group_chat_model.dart`, `message_model.dart`
2. Migrate `community_service.dart`
3. Migrate `chat_service.dart`
4. Update community and chat providers if needed

### Priority 3: Additional Features
1. Migrate remaining models
2. Migrate remaining services
3. Remove or update test files
4. Update screens that directly import Firebase

### Priority 4: File Storage
1. Migrate `storage_service.dart` to use PocketBase file uploads
2. PocketBase stores files directly in collection fields (type: file)
3. Update image/voice message handling

## PocketBase Server Setup

1. **Start PocketBase:**
   ```bash
   cd pocketbase
   ./pocketbase serve
   ```
   Server runs at: http://127.0.0.1:8090

2. **Create Admin Account:**
   Visit http://127.0.0.1:8090/_/ or run:
   ```bash
   ./pocketbase superuser upsert admin@example.com yourpassword
   ```

3. **Initialize Collections:**
   ```bash
   ./init_collections.sh
   ```
   This creates: users, communities, groupChats, messages collections

4. **Update Production URL:**
   In `lib/services/pocketbase_service.dart`, change:
   ```dart
   static const String _baseUrl = 'http://127.0.0.1:8090';
   ```
   to your production PocketBase URL when deploying.

## Testing

After migrating each component:
1. Run `flutter analyze` to check for errors
2. Test the specific feature (auth, communities, chat, etc.)
3. Check PocketBase admin panel for data
4. Verify real-time updates work

## Resources

- [PocketBase Docs](https://pocketbase.io/docs/)
- [Dart SDK](https://github.com/pocketbase/dart-sdk)
- [PocketBase Collections API](https://pocketbase.io/docs/api-collections/)
- [Real-time Subscriptions](https://pocketbase.io/docs/api-realtime/)
