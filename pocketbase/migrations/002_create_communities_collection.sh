#!/bin/bash

# Migration: Create communities collection

MIGRATION_NAME="002_create_communities_collection"
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
echo "📦 Creating communities collection..."

COLLECTION_SCHEMA='{
  "name": "communities",
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
        "min": null,
        "max": 500
      }
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
      "name": "communityImageUrl",
      "type": "url",
      "required": false
    },
    {
      "name": "inviteCode",
      "type": "text",
      "required": true,
      "options": {
        "min": 6,
        "max": 10,
        "pattern": ""
      }
    },
    {
      "name": "isActive",
      "type": "bool",
      "required": false
    },
    {
      "name": "memberIds",
      "type": "json",
      "required": false
    },
    {
      "name": "adminIds",
      "type": "json",
      "required": false
    },
    {
      "name": "groupChatIds",
      "type": "json",
      "required": false
    },
    {
      "name": "metadata",
      "type": "json",
      "required": false
    }
  ],
  "indexes": [
    "CREATE INDEX idx_communities_inviteCode ON communities (inviteCode)",
    "CREATE INDEX idx_communities_createdBy ON communities (createdBy)",
    "CREATE INDEX idx_communities_isActive ON communities (isActive)"
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
