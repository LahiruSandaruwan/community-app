#!/bin/bash

# PocketBase Database Migration Runner
# Runs all migrations in order to set up the complete database schema

set -e  # Exit on any error

echo "╔════════════════════════════════════════════════╗"
echo "║  EduConnect PocketBase Migration Runner       ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"
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

# Run migrations
echo "🚀 Running migrations..."
echo ""

MIGRATION_COUNT=0
MIGRATION_SUCCESS=0
MIGRATION_SKIP=0
MIGRATION_FAIL=0

for migration in "$MIGRATIONS_DIR"/*.sh; do
    if [ -f "$migration" ]; then
        MIGRATION_COUNT=$((MIGRATION_COUNT + 1))
        MIGRATION_NAME=$(basename "$migration")

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Make executable if not already
        chmod +x "$migration"

        # Run migration
        if bash "$migration"; then
            MIGRATION_SUCCESS=$((MIGRATION_SUCCESS + 1))
        else
            MIGRATION_FAIL=$((MIGRATION_FAIL + 1))
            echo "⚠️  Migration $MIGRATION_NAME encountered an issue"
        fi

        echo ""
    fi
done

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║           Migration Summary                    ║"
echo "╠════════════════════════════════════════════════╣"
echo "║  Total migrations: $MIGRATION_COUNT                         ║"
echo "║  Successful: $MIGRATION_SUCCESS                             ║"
echo "║  Failed: $MIGRATION_FAIL                                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

if [ $MIGRATION_FAIL -eq 0 ]; then
    echo "🎉 All migrations completed successfully!"
    echo ""
    echo "📋 Collections created:"
    echo "   • users (updated with custom fields)"
    echo "   • communities"
    echo "   • groupChats"
    echo "   • messages"
    echo "   • polls"
    echo "   • assignments"
    echo "   • bookmarks"
    echo "   • attendanceSessions"
    echo "   • userStats"
    echo "   • resources"
    echo "   • typing"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Run seeders to populate test data: ./seed.sh"
    echo "   2. Visit http://127.0.0.1:8090/_/ to view your database"
    echo "   3. Start the Flutter app and test authentication"
    exit 0
else
    echo "⚠️  Some migrations failed. Please check the errors above."
    exit 1
fi
