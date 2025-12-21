#!/bin/bash

# Migration: Create additional feature collections (polls, assignments, bookmarks, etc.)

MIGRATION_NAME="005_create_additional_collections"
BASE_URL="${POCKETBASE_URL:-http://127.0.0.1:8090}"
ADMIN_EMAIL="${POCKETBASE_ADMIN_EMAIL}"
ADMIN_PASSWORD="${POCKETBASE_ADMIN_PASSWORD}"

echo "🔄 Running migration: $MIGRATION_NAME"

# Check if credentials are provided
if [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    read -p "Enter admin email: " ADMIN_EMAIL
    read -sp "Enter admin password: " ADMIN_PASSWORD
    echo ""
fi

# Authenticate
AUTH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo $AUTH_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')

if [ -z "$TOKEN" ]; then
  echo "❌ Authentication failed"
  exit 1
fi

echo "✅ Authenticated"

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
    echo "✅ $COLLECTION_NAME created"
  else
    if echo "$RESPONSE" | grep -q "already exists"; then
      echo "⚠️  $COLLECTION_NAME already exists, skipping..."
    else
      echo "⚠️  Error creating $COLLECTION_NAME"
    fi
  fi
}

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
    {"name": "createdAt", "type": "date", "required": true},
    {"name": "expiresAt", "type": "date", "required": false},
    {"name": "allowMultiple", "type": "bool", "required": false},
    {"name": "isAnonymous", "type": "bool", "required": false}
  ]
}'
create_collection "$POLLS" "polls"

# Assignments Collection
ASSIGNMENTS='{
  "name": "assignments",
  "type": "base",
  "schema": [
    {"name": "title", "type": "text", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "createdAt", "type": "date", "required": true},
    {"name": "dueDate", "type": "date", "required": false},
    {"name": "maxPoints", "type": "number", "required": false},
    {"name": "isActive", "type": "bool", "required": false},
    {"name": "submittedBy", "type": "json", "required": false},
    {"name": "submissions", "type": "json", "required": false}
  ]
}'
create_collection "$ASSIGNMENTS" "assignments"

# Bookmarks Collection
BOOKMARKS='{
  "name": "bookmarks",
  "type": "base",
  "schema": [
    {"name": "userId", "type": "text", "required": true},
    {"name": "messageId", "type": "text", "required": true},
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdAt", "type": "date", "required": true}
  ]
}'
create_collection "$BOOKMARKS" "bookmarks"

# Attendance Sessions Collection
ATTENDANCE='{
  "name": "attendanceSessions",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "createdBy", "type": "text", "required": true},
    {"name": "startTime", "type": "date", "required": true},
    {"name": "endTime", "type": "date", "required": false},
    {"name": "presentUserIds", "type": "json", "required": false},
    {"name": "lateUserIds", "type": "json", "required": false},
    {"name": "isActive", "type": "bool", "required": false}
  ]
}'
create_collection "$ATTENDANCE" "attendanceSessions"

# User Stats Collection (for gamification)
USERSTATS='{
  "name": "userStats",
  "type": "base",
  "schema": [
    {"name": "userId", "type": "text", "required": true},
    {"name": "points", "type": "number", "required": false},
    {"name": "level", "type": "number", "required": false},
    {"name": "streak", "type": "number", "required": false},
    {"name": "lastActivityDate", "type": "date", "required": false},
    {"name": "achievements", "type": "json", "required": false},
    {"name": "activityCounts", "type": "json", "required": false}
  ]
}'
create_collection "$USERSTATS" "userStats"

# Resources Collection
RESOURCES='{
  "name": "resources",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "uploadedBy", "type": "text", "required": true},
    {"name": "fileName", "type": "text", "required": true},
    {"name": "fileType", "type": "text", "required": true},
    {"name": "fileSize", "type": "number", "required": true},
    {"name": "uploadedAt", "type": "date", "required": true},
    {"name": "description", "type": "text", "required": false},
    {"name": "file", "type": "file", "required": true, "options": {"maxSelect": 1, "maxSize": 52428800}}
  ]
}'
create_collection "$RESOURCES" "resources"

# Typing Indicators Collection
TYPING='{
  "name": "typing",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "text", "required": true},
    {"name": "userId", "type": "text", "required": true},
    {"name": "isTyping", "type": "bool", "required": true},
    {"name": "timestamp", "type": "date", "required": true}
  ]
}'
create_collection "$TYPING" "typing"

echo ""
echo "✅ Migration $MIGRATION_NAME completed successfully"
