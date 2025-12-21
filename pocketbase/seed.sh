#!/bin/bash

# PocketBase Database Seeder
# Populates the database with sample test data

set -e  # Exit on any error

echo "╔════════════════════════════════════════════════╗"
echo "║  EduConnect PocketBase Seeder                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEEDERS_DIR="$SCRIPT_DIR/seeders"
export POCKETBASE_URL="${POCKETBASE_URL:-http://127.0.0.1:8090}"

# Check if PocketBase is running
echo "🔍 Checking if PocketBase is running..."
if ! curl -s "$POCKETBASE_URL/api/health" > /dev/null 2>&1; then
    echo "❌ PocketBase is not running at $POCKETBASE_URL"
    echo "   Please start PocketBase first with: ./pocketbase serve"
    exit 1
fi
echo "✅ PocketBase is running"
echo ""

# Get admin credentials
if [ -z "$POCKETBASE_ADMIN_EMAIL" ] || [ -z "$POCKETBASE_ADMIN_PASSWORD" ]; then
    echo "📝 Please enter admin credentials:"
    read -p "Admin email: " POCKETBASE_ADMIN_EMAIL
    read -sp "Admin password: " POCKETBASE_ADMIN_PASSWORD
    echo ""
    echo ""
    export POCKETBASE_ADMIN_EMAIL
    export POCKETBASE_ADMIN_PASSWORD
fi

# Warning about existing data
echo "⚠️  WARNING: This will add sample data to your database."
echo "   If you want to start fresh, delete pb_data folder and run migrations first."
echo ""
read -p "Continue with seeding? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Seeding cancelled."
    exit 0
fi
echo ""

# Run seeders
echo "🌱 Running seeders..."
echo ""

SEEDER_COUNT=0
SEEDER_SUCCESS=0
SEEDER_FAIL=0

for seeder in "$SEEDERS_DIR"/*.sh; do
    if [ -f "$seeder" ]; then
        SEEDER_COUNT=$((SEEDER_COUNT + 1))
        SEEDER_NAME=$(basename "$seeder")

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Make executable if not already
        chmod +x "$seeder"

        # Run seeder
        if bash "$seeder"; then
            SEEDER_SUCCESS=$((SEEDER_SUCCESS + 1))
        else
            SEEDER_FAIL=$((SEEDER_FAIL + 1))
            echo "⚠️  Seeder $SEEDER_NAME encountered an issue"
        fi

        echo ""
    fi
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║           Seeding Summary                      ║"
echo "╠════════════════════════════════════════════════╣"
echo "║  Total seeders: $SEEDER_COUNT                           ║"
echo "║  Successful: $SEEDER_SUCCESS                            ║"
echo "║  Failed: $SEEDER_FAIL                                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

if [ $SEEDER_FAIL -eq 0 ]; then
    echo "🎉 All seeders completed successfully!"
    echo ""
    echo "📋 Test Data Created:"
    echo "   • 3 Tutors (tutor1@educonnect.com, etc.)"
    echo "   • 8 Students (student1@educonnect.com, etc.)"
    echo "   • 3 Communities with invite codes"
    echo ""
    echo "🔐 Login credentials:"
    echo "   Email: tutor1@educonnect.com"
    echo "   Password: password123"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Open the Flutter app"
    echo "   2. Login with test credentials"
    echo "   3. Explore the communities and features!"
    echo "   4. Visit http://127.0.0.1:8090/_/ to manage data"
    exit 0
else
    echo "⚠️  Some seeders failed. Please check the errors above."
    exit 1
fi
