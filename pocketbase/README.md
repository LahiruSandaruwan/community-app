# PocketBase Setup for EduConnect

## 🚀 Quick Start

### 1. Run Migrations (Auto-create Database Schema)

The migrations will automatically create all required collections (users, communities, groupChats, messages) with proper fields, indexes, and security rules.

```bash
# Stop the current PocketBase server (if running)
# Then run migrations
cd pocketbase
./pocketbase migrate
```

### 2. Start PocketBase Server

```bash
./pocketbase serve
```

The server will start at:
- **API**: http://127.0.0.1:8090/api/
- **Admin Dashboard**: http://127.0.0.1:8090/_/

### 3. Create Admin Account

On first run, PocketBase will show a setup URL. Open it in your browser to create your admin account, or run:

```bash
./pocketbase superuser upsert admin@example.com yourpassword
```

## 📁 Created Collections

The migrations create these collections automatically:

### 1. **users** (Auth Collection)
- Email/password authentication
- Fields: name, role (tutor/student), profilePictureUrl, phoneNumber, lastSeen, isOnline, fcmToken, communityIds, mutedGroupChatIds
- **Security**: Users can read all, update only their own profile

### 2. **communities**
- Fields: name, description, createdBy, communityImageUrl, inviteCode (unique), isActive, memberIds, adminIds, groupChatIds
- **Security**: Only tutors can create, members can view, admins can update

### 3. **groupChats**
- Fields: name, communityId, createdBy, isAnnouncementOnly, memberIds, lastMessage, lastMessageTime
- **Security**: Members can view, anyone authenticated can create, creator can delete

### 4. **messages**
- Fields: groupChatId, senderId, senderName, text, type, imageUrl, voiceUrl, isPinned, readBy, replyToId
- **Security**: Anyone authenticated can create, sender can update/delete

## 🔐 Security Rules

All collections have built-in security rules:
- Users must be authenticated to access data
- Role-based access (tutors can create communities)
- Ownership-based updates (users can only update their own data)
- Relation-based access (members can only see their communities/chats)

## 📝 Migration Files

Located in `pb_migrations/`:
- `1731667200_initial_schema.js` - Users collection
- `1731667201_communities_schema.js` - Communities collection
- `1731667202_groupchats_schema.js` - Group chats collection
- `1731667203_messages_schema.js` - Messages collection

## 🔄 Re-running Migrations

If you need to reset the database:

```bash
# Stop the server
# Delete the database
rm -rf pb_data/data.db*

# Run migrations again
./pocketbase migrate

# Restart server
./pocketbase serve
```

## 📊 Accessing the Admin Dashboard

1. Open http://127.0.0.1:8090/_/
2. Login with your admin credentials
3. View/manage all collections and data

## 🔌 Connecting from Flutter

```dart
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

// Sign up
await pb.collection('users').create(body: {
  'email': 'user@example.com',
  'password': 'password123',
  'passwordConfirm': 'password123',
  'name': 'John Doe',
  'role': 'student',
  'emailVisibility': true,
});

// Sign in
await pb.collection('users').authWithPassword(
  'user@example.com',
  'password123',
);

// Create a community (tutor only)
await pb.collection('communities').create(body: {
  'name': 'Math Class',
  'description': 'Grade 10 Mathematics',
  'createdBy': pb.authStore.record!.id,
  'inviteCode': 'MATH2024',
  'adminIds': [pb.authStore.record!.id],
  'memberIds': [pb.authStore.record!.id],
});

// Subscribe to real-time messages
pb.collection('messages').subscribe('*', (e) {
  print('New message: ${e.record}');
});
```

## 🎯 Next Steps

1. ✅ Migrations created
2. ⏳ Run `./pocketbase migrate` to create collections
3. ⏳ Start server with `./pocketbase serve`
4. ⏳ Create admin account
5. ⏳ Update Flutter app to use PocketBase
6. ⏳ Test authentication and data operations

## 📚 Resources

- [PocketBase Docs](https://pocketbase.io/docs/)
- [Dart/Flutter SDK](https://github.com/pocketbase/dart-sdk)
- [API Rules & Filters](https://pocketbase.io/docs/api-rules-and-filters/)
