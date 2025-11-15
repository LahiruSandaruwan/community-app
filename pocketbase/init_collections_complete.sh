#!/bin/bash

# Complete PocketBase Collections Initialization Script for EduConnect
# This creates ALL collections needed for the app after migration from Firebase

echo "🚀 Initializing ALL PocketBase Collections for EduConnect..."
echo ""
echo "⚠️  Make sure PocketBase is running and you have created an admin account"
echo ""

# Base URL
BASE_URL="http://127.0.0.1:8090"

# Prompt for admin credentials
read -p "Enter admin email: " ADMIN_EMAIL
read -sp "Enter admin password: " ADMIN_PASSWORD
echo ""

# Login and get auth token
echo "🔐 Authenticating..."
AUTH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo $AUTH_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')

if [ -z "$TOKEN" ]; then
  echo "❌ Authentication failed. Please check your credentials."
  exit 1
fi

echo "✅ Authenticated successfully"
echo ""

# Function to create collection
create_collection() {
  local COLLECTION_DATA=$1
  local COLLECTION_NAME=$2

  echo "📦 Creating $COLLECTION_NAME collection..."

  RESPONSE=$(curl -s -X POST "$BASE_URL/api/collections" \
    -H "Authorization: $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$COLLECTION_DATA")

  if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ $COLLECTION_NAME created successfully"
  else
    echo "⚠️  $COLLECTION_NAME might already exist or error occurred"
    echo "$RESPONSE"
  fi
  echo ""
}

# ==================== CORE COLLECTIONS ====================

# Communities Collection
COMMUNITIES='{
  "name": "communities",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "createdAt", "type": "text", "required": true},
    {"name": "communityImageUrl", "type": "text", "required": false},
    {"name": "inviteCode", "type": "text", "required": true},
    {"name": "isActive", "type": "bool", "required": false},
    {"name": "memberIds", "type": "json", "required": false},
    {"name": "adminIds", "type": "json", "required": false},
    {"name": "groupChatIds", "type": "json", "required": false},
    {"name": "metadata", "type": "json", "required": false}
  ]
}'

create_collection "$COMMUNITIES" "communities"

# GroupChats Collection
GROUPCHATS='{
  "name": "groupChats",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "communityId", "type": "text", "required": true},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "createdAt", "type": "text", "required": true},
    {"name": "groupImageUrl", "type": "text", "required": false},
    {"name": "memberIds", "type": "json", "required": false},
    {"name": "isAnnouncementOnly", "type": "bool", "required": false},
    {"name": "lastMessageAt", "type": "text", "required": false},
    {"name": "lastMessage", "type": "text", "required": false},
    {"name": "lastMessageSenderId", "type": "text", "required": false},
    {"name": "unreadCounts", "type": "json", "required": false},
    {"name": "pinnedMessageIds", "type": "json", "required": false},
    {"name": "isActive", "type": "bool", "required": false}
  ]
}'

create_collection "$GROUPCHATS" "groupChats"

# Messages Collection (NO LONGER A SUBCOLLECTION)
MESSAGES='{
  "name": "messages",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "senderId", "type": "text", "required": true},
    {"name": "senderName", "type": "text", "required": true},
    {"name": "senderProfileUrl", "type": "text", "required": false},
    {"name": "content", "type": "text", "required": true},
    {"name": "messageType", "type": "text", "required": false},
    {"name": "timestamp", "type": "text", "required": true},
    {"name": "readBy", "type": "json", "required": false},
    {"name": "isPinned", "type": "bool", "required": false},
    {"name": "replyToMessageId", "type": "text", "required": false},
    {"name": "metadata", "type": "json", "required": false},
    {"name": "reactions", "type": "json", "required": false}
  ]
}'

create_collection "$MESSAGES" "messages"

# Typing Indicators Collection (NEW - for real-time typing)
TYPING='{
  "name": "typing",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "userId", "type": "text", "required": true},
    {"name": "isTyping", "type": "bool", "required": true},
    {"name": "timestamp", "type": "text", "required": true}
  ]
}'

create_collection "$TYPING" "typing"

# ==================== FEATURE COLLECTIONS ====================

# Assignments Collection
ASSIGNMENTS='{
  "name": "assignments",
  "type": "base",
  "schema": [
    {"name": "title", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "createdAt", "type": "text", "required": true},
    {"name": "dueDate", "type": "text", "required": false},
    {"name": "maxPoints", "type": "number", "required": false},
    {"name": "isActive", "type": "bool", "required": false},
    {"name": "submittedBy", "type": "json", "required": false},
    {"name": "submissions", "type": "json", "required": false}
  ]
}'

create_collection "$ASSIGNMENTS" "assignments"

# Attendance Sessions Collection
ATTENDANCE='{
  "name": "attendanceSessions",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "startTime", "type": "text", "required": true},
    {"name": "endTime", "type": "text", "required": false},
    {"name": "presentUserIds", "type": "json", "required": false},
    {"name": "lateUserIds", "type": "json", "required": false},
    {"name": "isActive", "type": "bool", "required": false}
  ]
}'

create_collection "$ATTENDANCE" "attendanceSessions"

# Bookmarks Collection (NOW FLAT STRUCTURE)
BOOKMARKS='{
  "name": "bookmarks",
  "type": "base",
  "schema": [
    {"name": "userId", "type": "text", "required": true},
    {"name": "messageId", "type": "text", "required": true},
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdAt", "type": "text", "required": true}
  ]
}'

create_collection "$BOOKMARKS" "bookmarks"

# Polls Collection
POLLS='{
  "name": "polls",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "question", "type": "text", "required": true},
    {"name": "options", "type": "json", "required": true},
    {"name": "votes", "type": "json", "required": false},
    {"name": "createdAt", "type": "text", "required": true},
    {"name": "expiresAt", "type": "text", "required": false},
    {"name": "allowMultiple", "type": "bool", "required": false},
    {"name": "isAnonymous", "type": "bool", "required": false}
  ]
}'

create_collection "$POLLS" "polls"

# Resources Collection (with file upload support)
RESOURCES='{
  "name": "resources",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "uploadedBy", "type": "text", "required": true},
    {"name": "fileName", "type": "text", "required": true},
    {"name": "fileType", "type": "text", "required": true},
    {"name": "fileSize", "type": "number", "required": true},
    {"name": "uploadedAt", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "file", "type": "file", "required": true}
  ]
}'

create_collection "$RESOURCES" "resources"

# User Stats Collection (for gamification)
USERSTATS='{
  "name": "userStats",
  "type": "base",
  "schema": [
    {"name": "userId", "type": "text", "required": true},
    {"name": "points", "type": "number", "required": false},
    {"name": "level", "type": "number", "required": false},
    {"name": "streak", "type": "number", "required": false},
    {"name": "lastActivityDate", "type": "text", "required": false},
    {"name": "achievements", "type": "json", "required": false},
    {"name": "activityCounts", "type": "json", "required": false}
  ]
}'

create_collection "$USERSTATS" "userStats"

# Chat Images Collection (for storing uploaded images)
CHATIMAGES='{
  "name": "chat_images",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "uploadedBy", "type": "text", "required": true},
    {"name": "uploadedAt", "type": "text", "required": true},
    {"name": "image", "type": "file", "required": true}
  ]
}'

create_collection "$CHATIMAGES" "chat_images"

echo "✨ All collections created successfully!"
echo ""
echo "📝 Collections created:"
echo "  ✅ communities"
echo "  ✅ groupChats"
echo "  ✅ messages (flat structure)"
echo "  ✅ typing (new)"
echo "  ✅ assignments"
echo "  ✅ attendanceSessions"
echo "  ✅ bookmarks (flat structure)"
echo "  ✅ polls"
echo "  ✅ resources"
echo "  ✅ userStats"
echo "  ✅ chat_images"
echo ""
echo "🎯 Next steps:"
echo "1. Visit http://127.0.0.1:8090/_/ to view your collections"
echo "2. The 'users' collection is created automatically by PocketBase"
echo "3. Update your Flutter app to use PocketBase (already done!)"
echo "4. Test authentication and data operations"
