#!/bin/bash

# This script automatically creates all collections in PocketBase using the Admin API
# Run this after starting PocketBase and creating an admin account

echo "🚀 Initializing PocketBase Collections for EduConnect..."
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

# Users collection is created by default, we just need to add fields via migrations
# So we'll create the other collections

# Communities Collection
COMMUNITIES='{
  "name": "communities",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true, "options": {"min": 1, "max": 100}},
    {"name": "description", "type": "text", "required": false, "options": {"max": 500}},
    {"name": "createdBy", "type": "relation", "required": true, "options": {"collectionId": "_pb_users_auth_", "cascadeDelete": false, "maxSelect": 1}},
    {"name": "communityImageUrl", "type": "url", "required": false},
    {"name": "inviteCode", "type": "text", "required": true, "options": {"min": 6, "max": 10, "pattern": "^[A-Z0-9]+$"}},
    {"name": "isActive", "type": "bool", "required": false},
    {"name": "memberIds", "type": "json", "required": false},
    {"name": "adminIds", "type": "json", "required": false},
    {"name": "groupChatIds", "type": "json", "required": false}
  ],
  "indexes": ["CREATE UNIQUE INDEX idx_inviteCode ON communities (inviteCode)"],
  "listRule": "@request.auth.id != \"\" && (memberIds ?~ @request.auth.id || createdBy = @request.auth.id)",
  "viewRule": "@request.auth.id != \"\" && (memberIds ?~ @request.auth.id || createdBy = @request.auth.id)",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "@request.auth.id != \"\" && adminIds ?~ @request.auth.id",
  "deleteRule": "@request.auth.id != \"\" && createdBy = @request.auth.id"
}'

create_collection "$COMMUNITIES" "communities"

# GroupChats Collection
GROUPCHATS='{
  "name": "groupChats",
  "type": "base",
  "schema": [
    {"name": "name", "type": "text", "required": true, "options": {"min": 1, "max": 100}},
    {"name": "communityId", "type": "relation", "required": true, "options": {"collectionId": "communities", "cascadeDelete": true, "maxSelect": 1}},
    {"name": "createdBy", "type": "relation", "required": true, "options": {"collectionId": "_pb_users_auth_", "cascadeDelete": false, "maxSelect": 1}},
    {"name": "isAnnouncementOnly", "type": "bool", "required": false},
    {"name": "memberIds", "type": "json", "required": false},
    {"name": "lastMessage", "type": "text", "required": false},
    {"name": "lastMessageTime", "type": "date", "required": false}
  ],
  "listRule": "@request.auth.id != \"\" && memberIds ?~ @request.auth.id",
  "viewRule": "@request.auth.id != \"\" && memberIds ?~ @request.auth.id",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "@request.auth.id != \"\"",
  "deleteRule": "@request.auth.id != \"\" && createdBy = @request.auth.id"
}'

create_collection "$GROUPCHATS" "groupChats"

# Messages Collection
MESSAGES='{
  "name": "messages",
  "type": "base",
  "schema": [
    {"name": "groupChatId", "type": "relation", "required": true, "options": {"collectionId": "groupChats", "cascadeDelete": true, "maxSelect": 1}},
    {"name": "senderId", "type": "relation", "required": true, "options": {"collectionId": "_pb_users_auth_", "cascadeDelete": false, "maxSelect": 1}},
    {"name": "senderName", "type": "text", "required": true},
    {"name": "text", "type": "text", "required": false, "options": {"max": 5000}},
    {"name": "type", "type": "select", "required": false, "options": {"maxSelect": 1, "values": ["text", "image", "voice", "announcement", "poll", "quiz", "assignment"]}},
    {"name": "imageUrl", "type": "url", "required": false},
    {"name": "voiceUrl", "type": "url", "required": false},
    {"name": "isPinned", "type": "bool", "required": false},
    {"name": "readBy", "type": "json", "required": false},
    {"name": "replyToId", "type": "relation", "required": false, "options": {"collectionId": "messages", "cascadeDelete": false, "maxSelect": 1}}
  ],
  "indexes": [
    "CREATE INDEX idx_groupChatId ON messages (groupChatId)",
    "CREATE INDEX idx_created ON messages (created)"
  ],
  "listRule": "@request.auth.id != \"\"",
  "viewRule": "@request.auth.id != \"\"",
  "createRule": "@request.auth.id != \"\"",
  "updateRule": "@request.auth.id != \"\" && senderId = @request.auth.id",
  "deleteRule": "@request.auth.id != \"\" && senderId = @request.auth.id"
}'

create_collection "$MESSAGES" "messages"

echo "✨ All collections created successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Visit http://127.0.0.1:8090/_/ to view your collections"
echo "2. Update your Flutter app to use PocketBase"
echo "3. Test the authentication and data operations"
