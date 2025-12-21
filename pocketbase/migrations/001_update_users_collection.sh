#!/bin/bash

# Migration: Update users collection with custom fields
# This adds all necessary fields for EduConnect to the PocketBase auth users collection

MIGRATION_NAME="001_update_users_collection"
BASE_URL="${POCKETBASE_URL:-http://127.0.0.1:8090}"
ADMIN_EMAIL="${POCKETBASE_ADMIN_EMAIL}"
ADMIN_PASSWORD="${POCKETBASE_ADMIN_PASSWORD}"

echo "🔄 Running migration: $MIGRATION_NAME"

# Check if credentials are provided
if [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "⚠️  Admin credentials not provided in environment variables"
    read -p "Enter admin email: " ADMIN_EMAIL
    read -sp "Enter admin password: " ADMIN_PASSWORD
    echo ""
fi

# Authenticate
echo "🔐 Authenticating..."
AUTH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo $AUTH_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')

if [ -z "$TOKEN" ]; then
  echo "❌ Authentication failed"
  exit 1
fi

echo "✅ Authenticated"

# Get users collection ID
COLLECTIONS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/collections" \
  -H "Authorization: $TOKEN")

USERS_ID=$(echo $COLLECTIONS_RESPONSE | grep -o '"id":"[^"]*","name":"users"' | grep -o '"id":"[^"]*' | sed 's/"id":"//')

if [ -z "$USERS_ID" ]; then
  echo "❌ Users collection not found"
  exit 1
fi

echo "📦 Updating users collection schema..."

# Update schema with custom fields
UPDATED_SCHEMA='{
  "schema": [
    {
      "id": "users_avatar",
      "name": "avatar",
      "type": "file",
      "system": true,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "mimeTypes": ["image/jpeg", "image/png", "image/svg+xml", "image/gif", "image/webp"],
        "thumbs": null,
        "maxSelect": 1,
        "maxSize": 5242880,
        "protected": false
      }
    },
    {
      "id": "role_field",
      "name": "role",
      "type": "select",
      "system": false,
      "required": true,
      "presentable": false,
      "unique": false,
      "options": {
        "maxSelect": 1,
        "values": ["student", "tutor"]
      }
    },
    {
      "id": "phone_field",
      "name": "phoneNumber",
      "type": "text",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "min": null,
        "max": 20,
        "pattern": ""
      }
    },
    {
      "id": "fcm_field",
      "name": "fcmToken",
      "type": "text",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "min": null,
        "max": null,
        "pattern": ""
      }
    },
    {
      "id": "last_seen_field",
      "name": "lastSeen",
      "type": "date",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "min": "",
        "max": ""
      }
    },
    {
      "id": "is_online_field",
      "name": "isOnline",
      "type": "bool",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {}
    },
    {
      "id": "community_ids_field",
      "name": "communityIds",
      "type": "json",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "maxSize": 2000000
      }
    },
    {
      "id": "muted_field",
      "name": "mutedGroupChatIds",
      "type": "json",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "maxSize": 2000000
      }
    },
    {
      "id": "profile_pic_field",
      "name": "profilePictureUrl",
      "type": "url",
      "system": false,
      "required": false,
      "presentable": false,
      "unique": false,
      "options": {
        "exceptDomains": null,
        "onlyDomains": null
      }
    }
  ]
}'

RESPONSE=$(curl -s -X PATCH "$BASE_URL/api/collections/$USERS_ID" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$UPDATED_SCHEMA")

if echo "$RESPONSE" | grep -q '"id"'; then
  echo "✅ Migration $MIGRATION_NAME completed successfully"
  echo ""
  echo "Added fields:"
  echo "  • role (select: student/tutor) - REQUIRED"
  echo "  • phoneNumber (text)"
  echo "  • fcmToken (text)"
  echo "  • lastSeen (date)"
  echo "  • isOnline (bool)"
  echo "  • communityIds (json)"
  echo "  • mutedGroupChatIds (json)"
  echo "  • profilePictureUrl (url)"
else
  echo "❌ Migration failed"
  echo "$RESPONSE"
  exit 1
fi
