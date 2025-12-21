#!/bin/bash

# Migration: Create messages collection

MIGRATION_NAME="004_create_messages_collection"
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
echo "📦 Creating messages collection..."

COLLECTION_SCHEMA='{
  "name": "messages",
  "type": "base",
  "schema": [
    {
      "name": "groupChatId",
      "type": "text",
      "required": true
    },
    {
      "name": "senderId",
      "type": "text",
      "required": true
    },
    {
      "name": "senderName",
      "type": "text",
      "required": true
    },
    {
      "name": "senderProfileUrl",
      "type": "url",
      "required": false
    },
    {
      "name": "content",
      "type": "text",
      "required": true,
      "options": {
        "max": 1000
      }
    },
    {
      "name": "messageType",
      "type": "select",
      "required": false,
      "options": {
        "maxSelect": 1,
        "values": ["text", "image", "voice", "announcement", "poll", "quiz", "assignment"]
      }
    },
    {
      "name": "timestamp",
      "type": "date",
      "required": true
    },
    {
      "name": "readBy",
      "type": "json",
      "required": false
    },
    {
      "name": "isPinned",
      "type": "bool",
      "required": false
    },
    {
      "name": "replyToMessageId",
      "type": "text",
      "required": false
    },
    {
      "name": "metadata",
      "type": "json",
      "required": false
    },
    {
      "name": "reactions",
      "type": "json",
      "required": false
    }
  ],
  "indexes": [
    "CREATE INDEX idx_messages_groupChatId ON messages (groupChatId)",
    "CREATE INDEX idx_messages_senderId ON messages (senderId)",
    "CREATE INDEX idx_messages_timestamp ON messages (timestamp)"
  ]
}'

RESPONSE=$(curl -s -X POST "$BASE_URL/api/collections" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$COLLECTION_SCHEMA")

if echo "$RESPONSE" | grep -q '"id"'; then
  echo "✅ Migration $MIGRATION_NAME completed successfully"
else
  if echo "$RESPONSE" | grep -q "already exists"; then
    echo "⚠️  Collection already exists, skipping..."
  else
    echo "❌ Migration failed"
    echo "$RESPONSE"
    exit 1
  fi
fi
