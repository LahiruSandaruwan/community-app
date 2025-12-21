#!/bin/bash

# Seeder: Create sample communities with group chats

SEEDER_NAME="002_seed_communities"
BASE_URL="${POCKETBASE_URL:-http://127.0.0.1:8090}"
ADMIN_EMAIL="${POCKETBASE_ADMIN_EMAIL}"
ADMIN_PASSWORD="${POCKETBASE_ADMIN_PASSWORD}"

echo "🌱 Running seeder: $SEEDER_NAME"

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

# Get tutor1 user ID
echo "📋 Fetching user IDs..."
USERS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/collections/users/records?filter=(email='tutor1@educonnect.com')" \
  -H "Authorization: $TOKEN")

TUTOR1_ID=$(echo $USERS_RESPONSE | grep -o '"id":"[^"]*' | head -1 | sed 's/"id":"//')

if [ -z "$TUTOR1_ID" ]; then
  echo "❌ Could not find tutor1@educonnect.com. Please run user seeder first."
  exit 1
fi

echo "👥 Creating sample communities..."

# Function to create community
create_community() {
    local NAME=$1
    local DESCRIPTION=$2
    local INVITE_CODE=$3

    COMMUNITY_DATA=$(cat <<EOF
{
  "name": "$NAME",
  "description": "$DESCRIPTION",
  "createdBy": "$TUTOR1_ID",
  "createdAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "inviteCode": "$INVITE_CODE",
  "isActive": true,
  "memberIds": ["$TUTOR1_ID"],
  "adminIds": ["$TUTOR1_ID"],
  "groupChatIds": []
}
EOF
)

    RESPONSE=$(curl -s -X POST "$BASE_URL/api/collections/communities/records" \
      -H "Authorization: $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$COMMUNITY_DATA")

    if echo "$RESPONSE" | grep -q '"id"'; then
        COMMUNITY_ID=$(echo $RESPONSE | grep -o '"id":"[^"]*' | head -1 | sed 's/"id":"//')
        echo "  ✅ Created community: $NAME (Code: $INVITE_CODE)"
        echo "$COMMUNITY_ID"
    else
        if echo "$RESPONSE" | grep -q "already exists"; then
            echo "  ⚠️  Community $NAME already exists, skipping..."
        else
            echo "  ⚠️  Failed to create $NAME"
        fi
        echo ""
    fi
}

# Create Communities
echo ""
MATH_COMM=$(create_community "Mathematics 101" "Learn advanced mathematics concepts" "MATH101")
PHYSICS_COMM=$(create_community "Physics Advanced" "Master physics fundamentals" "PHYS201")
CODING_COMM=$(create_community "Coding Bootcamp" "Full-stack development course" "CODE301")

echo ""
echo "✅ Seeder $SEEDER_NAME completed"
echo ""
echo "📋 Created 3 communities:"
echo "   • Mathematics 101 (Code: MATH101)"
echo "   • Physics Advanced (Code: PHYS201)"
echo "   • Coding Bootcamp (Code: CODE301)"
echo ""
echo "💡 Students can join using these invite codes!"
