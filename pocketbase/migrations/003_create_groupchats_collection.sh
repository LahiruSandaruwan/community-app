#!/bin/bash

# Migration: Create groupChats collection

MIGRATION_NAME="003_create_groupchats_collection"
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
echo "📦 Creating groupChats collection..."

COLLECTION_SCHEMA='{
  "name": "groupChats",
  "type": "base",
  "schema": [
    {
      "name": "name",
      "type": "text",
      "required": true,
      "options": {
        "min": 2,
        "max": 50
      }
    },
    {
      "name": "description",
      "type": "text",
      "required": false,
      "options": {
        "max": 500
      }
    },
    {
      "name": "communityId",
      "type": "text",
      "required": true
    },
    {
      "name": "createdBy",
      "type": "text",
      "required": true
    },
    {
      "name": "createdAt",
      "type": "date",
      "required": true
    },
    {
      "name": "groupImageUrl",
      "type": "url",
      "required": false
    },
    {
      "name": "memberIds",
      "type": "json",
      "required": false
    },
    {
      "name": "isAnnouncementOnly",
      "type": "bool",
      "required": false
    },
    {
      "name": "lastMessageAt",
      "type": "date",
      "required": false
    },
    {
      "name": "lastMessage",
      "type": "text",
      "required": false
    },
    {
      "name": "lastMessageSenderId",
      "type": "text",
      "required": false
    },
    {
      "name": "unreadCounts",
      "type": "json",
      "required": false
    },
    {
      "name": "pinnedMessageIds",
      "type": "json",
      "required": false
    },
    {
      "name": "isActive",
      "type": "bool",
      "required": false
    }
  ],
  "indexes": [
    "CREATE INDEX idx_groupchats_communityId ON groupChats (communityId)",
    "CREATE INDEX idx_groupchats_createdBy ON groupChats (createdBy)",
    "CREATE INDEX idx_groupchats_isActive ON groupChats (isActive)"
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
