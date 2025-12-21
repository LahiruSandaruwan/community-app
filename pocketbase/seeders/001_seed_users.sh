#!/bin/bash

# Seeder: Create sample users (tutors and students)

SEEDER_NAME="001_seed_users"
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
echo "👥 Creating sample users..."

# Function to create user
create_user() {
    local EMAIL=$1
    local PASSWORD=$2
    local NAME=$3
    local ROLE=$4

    USER_DATA=$(cat <<EOF
{
  "email": "$EMAIL",
  "password": "$PASSWORD",
  "passwordConfirm": "$PASSWORD",
  "name": "$NAME",
  "role": "$ROLE",
  "emailVisibility": true,
  "isOnline": false,
  "communityIds": [],
  "mutedGroupChatIds": []
}
EOF
)

    RESPONSE=$(curl -s -X POST "$BASE_URL/api/collections/users/records" \
      -H "Authorization: $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$USER_DATA")

    if echo "$RESPONSE" | grep -q '"id"'; then
        echo "  ✅ Created $ROLE: $NAME ($EMAIL)"
    else
        if echo "$RESPONSE" | grep -q "already exists"; then
            echo "  ⚠️  User $EMAIL already exists, skipping..."
        else
            echo "  ⚠️  Failed to create $EMAIL"
        fi
    fi
}

# Create Tutors
echo ""
echo "Creating tutors..."
create_user "tutor1@educonnect.com" "password123" "Dr. Sarah Johnson" "tutor"
create_user "tutor2@educonnect.com" "password123" "Prof. Michael Chen" "tutor"
create_user "tutor3@educonnect.com" "password123" "Ms. Emily Davis" "tutor"

# Create Students
echo ""
echo "Creating students..."
create_user "student1@educonnect.com" "password123" "John Smith" "student"
create_user "student2@educonnect.com" "password123" "Emma Wilson" "student"
create_user "student3@educonnect.com" "password123" "David Brown" "student"
create_user "student4@educonnect.com" "password123" "Sophia Martinez" "student"
create_user "student5@educonnect.com" "password123" "James Taylor" "student"
create_user "student6@educonnect.com" "password123" "Olivia Anderson" "student"
create_user "student7@educonnect.com" "password123" "Lucas Garcia" "student"
create_user "student8@educonnect.com" "password123" "Ava Rodriguez" "student"

echo ""
echo "✅ Seeder $SEEDER_NAME completed"
echo ""
echo "📋 Created:"
echo "   • 3 Tutors"
echo "   • 8 Students"
echo ""
echo "   Password for all users: password123"
